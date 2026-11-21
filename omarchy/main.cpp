// livewall for Omarchy (Hyprland): any HTML page as a live wallpaper.
// Usage: livewall [path/to/page.html]

#include <QGuiApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegion>
#include <QScreen>
#include <QTimer>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickView>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <LayerShellQt/Window>

// Caps requestAnimationFrame at 20 fps and lets the app pause it.
static const char *kThrottle = R"JS(
(function(){var raf=window.requestAnimationFrame.bind(window),iv=1000/20,paused=false,q=[];
window.requestAnimationFrame=function(cb){if(paused){q.push(cb);return 0}
var s=Math.floor(performance.now()/iv);
return raf(function loop(t){if(Math.floor(t/iv)<=s)return raf(loop);if(paused){q.push(cb);return}cb(t)})};
window.__lw=function(p){paused=p;if(!p){var c=q;q=[];c.forEach(function(f){window.requestAnimationFrame(f)})}};})();
)JS";

struct Wall {
  QScreen *screen;
  QQuickView *view;
  int paused = -1;
};

class App : public QObject {
public:
  explicit App(const QString &html) : html_(html) {
    connect(qApp, &QGuiApplication::screenAdded, this, &App::build);
    connect(qApp, &QGuiApplication::screenRemoved, this, &App::build);
    connect(&timer_, &QTimer::timeout, this, &App::refresh);
    timer_.start(2000);
    build();
  }

private:
  QString html_;
  QList<Wall> walls_;
  QTimer timer_;
  bool busy_ = false;

  void build() {
    for (auto &w : walls_) w.view->deleteLater();
    walls_.clear();
    for (QScreen *screen : QGuiApplication::screens()) {
      auto *view = new QQuickView;
      view->setScreen(screen);
      view->setColor(Qt::black);
      // Configure the layer surface before the window exists.
      if (auto *lw = LayerShellQt::Window::get(view)) {
        lw->setLayer(LayerShellQt::Window::LayerBackground);
        lw->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom |
            LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight));
        lw->setExclusiveZone(-1);
        lw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
        lw->setScope("livewall");
        lw->setScreen(screen);
      }
      view->rootContext()->setContextProperty("wallUrl", QUrl::fromLocalFile(html_));
      view->rootContext()->setContextProperty("throttleSource", QString::fromUtf8(kThrottle));
      view->setResizeMode(QQuickView::SizeRootObjectToView);
      view->setSource(QUrl("qrc:/Wall.qml"));
      view->resize(screen->size());
      view->show();
      // Clicks pass through: an empty input region.
      view->setMask(QRegion(-1, -1, 1, 1));
      walls_.append({screen, view});
    }
    refresh();
  }

  static bool onBattery() {
    bool battery = false, mains = false;
    for (const QFileInfo &fi : QDir("/sys/class/power_supply").entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
      QFile t(fi.filePath() + "/type");
      if (!t.open(QIODevice::ReadOnly)) continue;
      const QByteArray type = t.readAll().trimmed();
      if (type == "Battery") {
        QFile st(fi.filePath() + "/status");
        if (st.open(QIODevice::ReadOnly) && st.readAll().trimmed() == "Discharging") battery = true;
      } else if (type == "Mains") {
        QFile on(fi.filePath() + "/online");
        if (on.open(QIODevice::ReadOnly) && on.readAll().trimmed() == "1") mains = true;
      }
    }
    return battery && !mains;
  }

  static QJsonArray hyprctl(const QString &what) {
    QProcess p;
    p.start("hyprctl", {"-j", what});
    if (!p.waitForFinished(1500)) { p.kill(); return {}; }
    return QJsonDocument::fromJson(p.readAllStandardOutput()).array();
  }

  static bool locked() {
    QProcess p;
    p.start("pgrep", {"-x", "hyprlock"});
    p.waitForFinished(1000);
    return p.exitCode() == 0;
  }

  // Paused = screen off, locked, on battery, or a window fills 90%+ of that monitor
  // (fullscreen games included, so the wallpaper never competes with them for the GPU).
  void refresh() {
    if (busy_) return;
    busy_ = true;
    const bool global = onBattery() || locked();
    const QJsonArray monitors = hyprctl("monitors");
    const QJsonArray clients = hyprctl("clients");

    for (auto &w : walls_) {
      bool p = global;
      if (!p) {
        for (const auto &mv : monitors) {
          const QJsonObject m = mv.toObject();
          if (m["name"].toString() != w.screen->name()) continue;
          if (!m["dpmsStatus"].toBool(true)) { p = true; break; }
          const double scale = m["scale"].toDouble(1.0);
          const double area = (m["width"].toDouble() / scale) * (m["height"].toDouble() / scale);
          const int ws = m["activeWorkspace"].toObject()["id"].toInt();
          const int special = m["specialWorkspace"].toObject()["id"].toInt();
          const int monId = m["id"].toInt();
          for (const auto &cv : clients) {
            const QJsonObject c = cv.toObject();
            if (!c["mapped"].toBool() || c["hidden"].toBool()) continue;
            if (c["monitor"].toInt() != monId) continue;
            const int cws = c["workspace"].toObject()["id"].toInt();
            if (cws != ws && !(special != 0 && cws == special)) continue;
            const QJsonArray sz = c["size"].toArray();
            const double a = sz.at(0).toDouble() * sz.at(1).toDouble();
            if (c["fullscreen"].toInt() > 0 || a >= area * 0.9) { p = true; break; }
          }
          break;
        }
      }
      {  // re-sent every tick: a page that was still loading would miss a one-off call
        w.paused = p;
        if (QQuickItem *root = w.view->rootObject())
          QMetaObject::invokeMethod(root, "setPaused", Q_ARG(QVariant, QVariant(p)));
      }
    }
    busy_ = false;
  }
};

int main(int argc, char **argv) {
  const QString html = argc > 1 ? QFileInfo(QString::fromLocal8Bit(argv[1])).absoluteFilePath()
                                : QDir::homePath() + "/.local/share/livewall/wallpaper.html";
  qputenv("QT_QPA_PLATFORM", "wayland");
  QtWebEngineQuick::initialize();
  QGuiApplication app(argc, argv);
  app.setApplicationName("livewall");
  app.setQuitOnLastWindowClosed(false);
  App a(html);
  return app.exec();
}
