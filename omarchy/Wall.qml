import QtQuick
import QtWebEngine

WebEngineView {
  id: web
  backgroundColor: "black"
  settings.showScrollBars: false
  settings.localContentCanAccessFileUrls: true
  settings.localContentCanAccessRemoteUrls: true
  onContextMenuRequested: (request) => request.accepted = true
  onJavaScriptConsoleMessage: (level, message, line, source) => console.log("page:", message, "(line " + line + ")")
  // a crashed renderer would leave a frozen frame: load the page again
  onRenderProcessTerminated: (status, code) => { console.log("page: renderer ended (" + status + "), reloading"); reloadTimer.start() }
  Timer { id: reloadTimer; interval: 1500; onTriggered: web.reload() }

  function setPaused(p) { runJavaScript("window.__lw&&__lw(" + (p ? "true" : "false") + ")") }

  Component.onCompleted: {
    var s = WebEngine.script()
    s.name = "livewall-throttle"
    s.sourceCode = throttleSource
    s.injectionPoint = WebEngineScript.DocumentCreation
    s.worldId = WebEngineScript.MainWorld
    userScripts.insert(s)
    url = wallUrl
  }
}
