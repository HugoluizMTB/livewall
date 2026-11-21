import Cocoa
import WebKit
import IOKit.ps

// Usage: livewall [path/to/page.html]
let htmlPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
  : NSHomeDirectory() + "/Library/Application Support/livewall/wallpaper.html"

// Caps requestAnimationFrame at 20 fps and lets the app pause it.
let throttle = """
(function(){var raf=window.requestAnimationFrame.bind(window),iv=1000/20,paused=false,q=[];
window.requestAnimationFrame=function(cb){if(paused){q.push(cb);return 0}
var s=Math.floor(performance.now()/iv);
return raf(function loop(t){if(Math.floor(t/iv)<=s)return raf(loop);if(paused){q.push(cb);return}cb(t)})};
window.__lw=function(p){paused=p;if(!p){var c=q;q=[];c.forEach(function(f){window.requestAnimationFrame(f)})}};})();
"""


final class App: NSObject, NSApplicationDelegate {
  var windows: [NSWindow] = []
  var webs: [WKWebView] = []
  var screensAsleep = false

  func applicationDidFinishLaunching(_ n: Notification) {
    build()
    NotificationCenter.default.addObserver(self, selector: #selector(build),
      name: NSApplication.didChangeScreenParametersNotification, object: nil)
    let ws = NSWorkspace.shared.notificationCenter
    for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
      ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.screensAsleep = true; self?.refresh() }
    }
    for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
      ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.screensAsleep = false; self?.refresh() }
    }
    Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
  }

  func onBattery() -> Bool {
    guard let type = IOPSGetProvidingPowerSourceType(nil)?.takeUnretainedValue() else { return false }
    return (type as String) == kIOPSBatteryPowerValue
  }

  // Covered = a normal window fills 90%+ of that screen.
  func covered(_ screen: NSRect) -> Bool {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return false }
    let primaryH = NSScreen.screens.first?.frame.height ?? 0
    for w in list {
      guard (w[kCGWindowLayer as String] as? Int) == 0,
            let b = w[kCGWindowBounds as String] as? [String: CGFloat],
            let x = b["X"], let y = b["Y"], let wd = b["Width"], let ht = b["Height"] else { continue }
      let r = NSRect(x: x, y: primaryH - y - ht, width: wd, height: ht)
      let i = r.intersection(screen)
      if i.width * i.height >= screen.width * screen.height * 0.9 { return true }
    }
    return false
  }

  func refresh() {
    let global = screensAsleep || onBattery()
    for (w, web) in zip(windows, webs) {
      let p = global || covered(w.frame)
      web.evaluateJavaScript("window.__lw&&__lw(\(p))")
    }
  }

  @objc func build() {
    windows.forEach { $0.close() }
    webs = []
    windows = NSScreen.screens.map { screen in
      let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
      w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
      w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
      w.ignoresMouseEvents = true
      w.isReleasedWhenClosed = false
      w.backgroundColor = .black
      let cfg = WKWebViewConfiguration()
      let ucc = cfg.userContentController
      ucc.addUserScript(WKUserScript(source: throttle, injectionTime: .atDocumentStart, forMainFrameOnly: true))
      let web = WKWebView(frame: CGRect(origin: .zero, size: screen.frame.size), configuration: cfg)
      web.autoresizingMask = [.width, .height]
      let url = URL(fileURLWithPath: htmlPath)
      web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
      w.contentView = web
      w.setFrame(screen.frame, display: true)
      w.orderBack(nil)
      webs.append(web)
      return w
    }
  }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
