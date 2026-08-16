import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.gpatkinson.btc-price"

  // ---- Panel lifecycle (forwarded to the loaded Panel.qml) ----

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  // ---- Layout ----

  // Hidden until the first successful fetch sets a label.
  visible: panelLoader.item && panelLoader.item.label !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  // ---- Panel loader (always active so the fetch timer runs) ----

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  // ---- Bar button ----

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: panelLoader.item ? panelLoader.item.label : ""
    // Bitcoin orange or bar default, toggled from the panel.
    foreground: panelLoader.item && panelLoader.item.priceColor
      ? panelLoader.item.priceColor
      : (root.bar ? root.bar.barForeground : "#f7931a")
    tooltipText: "Open Bitcoin Price"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
