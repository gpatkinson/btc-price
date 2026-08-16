import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "gpatkinson.btc-price"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  // ---- Panel lifecycle ----

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  // ---- Price data ----

  // The bar label string — read by BarWidget.qml. Empty until the first
  // successful fetch, which keeps the bar widget hidden during cold start.
  property string label: ""

  // Parsed CoinGecko response fields.
  property real priceUsd: 0
  property real change24h: 0
  property int lastUpdated: 0

  // True while a fetch is in flight (shows a spinner hint in the panel).
  property bool loading: false

  // Retry budget for transient failures (network down, API 429, etc.).
  property int retries: 0

  // CoinGecko free /simple/price endpoint — no API key required.
  // Rate limit is generous for a 15-minute poll; CoinGecko asks for a
  // courtesy delay of ~1-2 min between calls on the free tier.
  readonly property string apiUrl:
    "https://api.coingecko.com/api/v3/simple/price"
    + "?ids=bitcoin&vs_currencies=usd"
    + "&include_24hr_change=true"
    + "&include_last_updated_at=true"

  // ---- Fetch logic ----

  function refresh() {
    if (priceProc.running) return
    retries = 0
    loading = true
    priceProc.running = true
  }

  function scheduleRetry() {
    if (retries >= 3) return
    retries++
    retryTimer.restart()
  }

  // ---- UI helpers ----

  readonly property string displayPrice: Model.formatPrice(priceUsd)
  readonly property string displayChange: Model.formatChange(change24h)
  readonly property color  displayChangeColor: Model.changeColor(change24h)
  readonly property string displayUpdated: Model.formatUpdatedTime(lastUpdated)

  // ---- HTTP fetch via curl (same pattern as the built-in weather plugin) ----

  Process {
    id: priceProc
    command: ["curl", "-fsS", "--max-time", "10", root.apiUrl]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var raw = String(text || "").trim()
        if (!raw) {
          root.scheduleRetry()
          return
        }
        var parsed = Model.parsePriceResponse(raw)
        if (parsed) {
          root.priceUsd = parsed.usd
          root.change24h = parsed.change24h
          root.lastUpdated = parsed.lastUpdated
          root.label = Model.barLabel(parsed.usd)
          root.retries = 0
        } else {
          root.scheduleRetry()
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.loading = false
        root.scheduleRetry()
      }
    }
  }

  Timer {
    id: retryTimer
    interval: 5000
    onTriggered: if (!priceProc.running) priceProc.running = true
  }

  // 15-minute auto-refresh. triggeredOnStart fires immediately on load so
  // the first price appears within seconds of shell startup.
  Timer {
    id: refreshTimer
    interval: 15 * 60 * 1000  // 15 minutes
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---- Panel surface ----

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        // ---- Header ----

        Text {
          width: parent.width
          text: "Bitcoin"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        // ---- Current price (large) ----

        Text {
          width: parent.width
          text: root.displayPrice || (root.loading ? "Loading..." : "—")
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.displayLarge
        }

        // ---- 24h change ----

        Text {
          width: parent.width
          text: "24h: " + (root.displayChange || "—")
          color: root.displayChange ? root.displayChangeColor : root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        // ---- Last updated + source ----

        Text {
          width: parent.width
          text: root.displayUpdated
                ? "Updated " + root.displayUpdated
                : ""
          color: root.barForeground
          opacity: 0.6
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          visible: text !== ""
        }

        Text {
          width: parent.width
          text: "Source: CoinGecko"
          color: root.barForeground
          opacity: 0.4
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        // ---- Manual refresh button ----

        WidgetButton {
          width: parent.width
          bar: root.bar
          text: root.loading ? "Refreshing..." : "Refresh now"
          tooltipText: "Fetch the latest Bitcoin price"
          onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) root.refresh()
          }
        }
      }
    }
  }
}
