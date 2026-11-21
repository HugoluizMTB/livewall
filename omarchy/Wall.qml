import QtQuick
import QtWebEngine

WebEngineView {
  id: web
  backgroundColor: "black"
  settings.showScrollBars: false
  settings.localContentCanAccessFileUrls: true
  onContextMenuRequested: (request) => request.accepted = true

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
