import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import IslandBackend

PanelWindow {
  id: wifiListWindow

  property real anchorX: 0
  property real anchorY: 0

  anchors.top: true
  anchors.left: true
  margins.top: anchorY
  margins.left: anchorX

  property bool controlCenter: false
  property string passwordPromptSsid: ""
  property bool passwordPromptVisible: false
  property string passwordValue: ""

  // keyboard focus for password prompt
  WlrLayershell.keyboardFocus: passwordPromptVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  exclusionMode: ExclusionMode.Ignore
  width: 290
  height: 380
  color: "transparent"

  // auto hide if control center close
  onVisibleChanged: {
    if (visible && WifiController.enabled) WifiController.refreshNetworks(true)
  }

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.rightMargin: 30
    color: Theme.oneBg
    radius: 15

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      Text {
        text: "Wi-Fi"
        color: Theme.white
        font { family: Theme.fontFamily; pixelSize: 14; bold: true }
      }

      Text {
        visible: WifiController.scanning
        text: "Scanning..."
        color: Theme.greyFg2
        font { family: Theme.fontFamily; pixelSize: 11 }
      }

      Text {
        visible: !WifiController.enabled
        text: "Turn on the Wi-Fi to see networks."
        color: Theme.greyFg2
        font { family: Theme.fontFamily; pixelSize: 11 }
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: networkColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: networkColumn
          width: parent.width
          spacing: 4

          Repeater {
            // ssid, display name, type, signal, secure, saved connection and connected
            model: WifiController.enabled ? WifiController.networks : null

            delegate: Rectangle {
              width: networkColumn.width
              height: 50
              radius: 12
              color: connected ? Theme.color12 : (networkMouse.containsMouse ? Theme.oneBg3 : Theme.oneBg2)

              MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !WifiController.busy && WifiController.enabled
                onClicked: {
                  if (connected) {
                    WifiController.disconnectCurrent()
                    return
                  }
                  if (savedConnection || !secure) {
                    WifiController.connectToNetwork(ssid)
                    return
                  }
                  wifiListWindow.passwordPromptSsid = ssid
                  wifiListWindow.passwordPromptVisible = true
                }
              }

              Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: secure ? "\uf023" : "\uf09c"
                  font { family: Theme.nerdFontFamily; pixelSize: 12 }
                  color: Theme.lightGrey
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2
                  Text {
                    text: displayName || ssid
                    color: Theme.color15
                    font { family: Theme.fontFamily; pixelSize: 12; weight: connected ? 600 : 300 }
                  }
                  Text {
                    text: connected ? "Connected" : (signal >= 0 ? signal + "%" : "")
                    color: connected ? Theme.color15 : Theme.greyFg2
                    font { family: Theme.fontFamily; pixelSize: 10 }
                  }
                }
              }
            }
          }
        }
      }

      Text {
        visible: WifiController.errorMessage.length > 0
        text: WifiController.errorMessage
        color: Theme.color9
        font { family: Theme.fontFamily; pixelSize: 11 }
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    // password prompt overlay box
    Rectangle {
      visible: wifiListWindow.passwordPromptVisible
      onVisibleChanged: if (visible) passwordField.forceActiveFocus()
      anchors.fill: parent
      color: Theme.oneBg3
      radius: 13
      z: 10

      MouseArea { anchors.fill: parent }

      Column {
        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 12

        Text {
          width: parent.width
          text: "Password for " + wifiListWindow.passwordPromptSsid
          color: Theme.white
          font { family: Theme.fontFamily; pixelSize: 13; bold: true }
          wrapMode: Text.Wrap
        }

        Rectangle {
          width: parent.width
          height: 36
          radius: 8
          color: Theme.grey
          border.color: Theme.greyFg2
          border.width: 1

          TextInput {
            id: passwordField
            focus: true
            anchors.fill: parent
            anchors.margins: 10
            color: Theme.white
            font { family: Theme.fontFamily; pixelSize: 12 }
            echoMode: TextInput.Password
            verticalAlignment: TextInput.AlignVCenter
            onTextChanged: wifiListWindow.passwordValue = text
            Keys.onReturnPressed: submitBtn.clicked()
          }
        }

        Row {
          spacing: 8
          Rectangle {
            id: submitBtn
            width: 80; height: 32; radius: 8
            color: Theme.color12
            signal clicked()
            Text { anchors.centerIn: parent; text: "Join"; color: Theme.color15; font { family: Theme.fontFamily; pixelSize: 12 } }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                WifiController.connectToNetwork(wifiListWindow.passwordPromptSsid, wifiListWindow.passwordValue)
                wifiListWindow.passwordPromptVisible = false
                wifiListWindow.passwordValue = ""
                passwordField.text = ""
              }
            }
          }
          Rectangle {
            width: 80; height: 32; radius: 8
            color: Theme.oneBg2
            Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.white; font { family: Theme.fontFamily; pixelSize: 12 } }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                wifiListWindow.passwordPromptVisible = false
                wifiListWindow.passwordValue = ""
                passwordField.text = ""
              }
            }
          }
        }
      }
    }
  }
}
