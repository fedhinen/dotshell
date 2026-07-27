import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property bool expanded: true
    required property var parentWindow
    required property var menuAnchor

    spacing: 7

    IpcHandler {
        target: "systray"
        function toggle(): void { root.expanded = !root.expanded }
        function show(): void { root.expanded = true }
        function hide(): void { root.expanded = false }
    }

    Repeater {
        model: root.expanded ? SystemTray.items : null

        Item {
            required property var modelData
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18

            Image {
                anchors.fill: parent
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        const pos = mapToItem(root.menuAnchor, 0, height)
                        modelData.display(root.parentWindow,
                            root.menuAnchor.x + pos.x, root.menuAnchor.y + pos.y)
                    }
                    else if (mouse.button === Qt.MiddleButton)
                        modelData.secondaryActivate()
                    else
                        modelData.activate()
                }
            }
        }
    }

    Text {
        text: root.expanded ? String.fromCodePoint(0xf0140) : String.fromCodePoint(0xf0142)
        color: Theme.fg
        font {
            family: Theme.nerdFontFamily
            pixelSize: 14
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }
}
