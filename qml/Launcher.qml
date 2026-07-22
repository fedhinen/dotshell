import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root

    property bool shown: false

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    color: "transparent"

    anchors { top: true; left: true; right: true; bottom: true }

    function show() {
        searchInput.text = ""
        selectedIndex = 0
        shown = true
        searchInput.forceActiveFocus()
    }

    function hide() {
        shown = false
        hideTimer.restart()
        searchInput.text = ""
    }

    property int selectedIndex: 0
    property string searchQuery: ""

    property var filteredApps: {
        let q = searchQuery.toLowerCase().trim()
        let all = DesktopEntries.applications.values !== undefined
            ? DesktopEntries.applications.values
            : DesktopEntries.applications
        if (q.length === 0) return all.slice()
        return all.filter(e => {
            if (e.noDisplay) return false
            if (e.name.toLowerCase().includes(q)) return true
            if (e.genericName && e.genericName.toLowerCase().includes(q)) return true
            if (e.keywords && e.keywords.some(k => k.toLowerCase().includes(q))) return true
            return false
        })
    }

    onFilteredAppsChanged: selectedIndex = 0

    visible: shown || hideTimer.running

    Timer {
        id: hideTimer
        interval: 160
        repeat: false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: panel
        width: Math.min(parent.width * 0.56, 720)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        radius: 16
        color: "#ee171717"
        clip: true

        implicitHeight: contentCol.implicitHeight + 24

        opacity: shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

        scale: shown ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: "#232323"
                border.color: searchInput.activeFocus ? "#3a3a3a" : "#272727"
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font { family: Theme.fontFamily; pixelSize: 14 }
                    clip: true
                    selectByMouse: true

                    onTextChanged: root.searchQuery = text

                    Text {
                        text: "Search for anything..."
                        color: "#4a4a4a"
                        font: searchInput.font
                        visible: searchInput.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down) {
                            if (root.filteredApps.length > 0)
                                root.selectedIndex = (root.selectedIndex + 1) % root.filteredApps.length
                            appList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            if (root.filteredApps.length > 0)
                                root.selectedIndex = root.selectedIndex <= 0
                                    ? root.filteredApps.length - 1
                                    : root.selectedIndex - 1
                            appList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.filteredApps.length > 0) {
                                root.filteredApps[root.selectedIndex].execute()
                                root.hide()
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.hide()
                            event.accepted = true
                        }
                    }
                }
            }

            ListView {
                id: appList
                width: parent.width
                height: Math.min(contentHeight, 420)
                clip: true
                model: root.filteredApps
                currentIndex: root.selectedIndex
                highlightMoveDuration: 80
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3000
                maximumFlickVelocity: 2500

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: "#3a3a3a"
                    }
                }

                delegate: Rectangle {
                    id: appItem
                    width: appList.width
                    height: 64
                    radius: 8
                    color: index === root.selectedIndex ? "#2a2a2a" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    required property var modelData
                    required property int index

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 16
                        spacing: 14

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: "#1e1e1e"
                            clip: true

                            IconImage {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: "image://icon/" + (appItem.modelData.icon || "")
                                smooth: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appItem.modelData.icon === ""
                                text: appItem.modelData.name.charAt(0).toUpperCase()
                                color: Theme.accent
                                font { family: Theme.fontFamily; pixelSize: 16; weight: 700 }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                width: parent.width
                                text: appItem.modelData.name
                                color: Theme.fg
                                font { family: Theme.fontFamily; pixelSize: 13; weight: 600 }
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: appItem.modelData.genericName || appItem.modelData.id
                                color: "#606060"
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }

                        Text {
                            text: appItem.modelData.categories.length > 0
                                ? appItem.modelData.categories[0]
                                : ""
                            color: "#484848"
                            font { family: Theme.fontFamily; pixelSize: 11 }
                            visible: text.length > 0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = appItem.index
                            appItem.modelData.execute()
                            root.hide()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#242424"
                visible: appList.contentHeight > 0
            }

            RowLayout {
                width: parent.width
                height: 28

                Text {
                    text: "Applications"
                    color: "#3a3a3a"
                    font { family: Theme.fontFamily; pixelSize: 10 }
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 10

                    Row {
                        spacing: 5
                        Text {
                            text: "Navigate"
                            color: "#3a3a3a"
                            font { family: Theme.fontFamily; pixelSize: 10 }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 4; color: "#252525"
                            Text { anchors.centerIn: parent; text: "↑"; color: "#606060"; font { family: Theme.fontFamily; pixelSize: 10 } }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 4; color: "#252525"
                            Text { anchors.centerIn: parent; text: "↓"; color: "#606060"; font { family: Theme.fontFamily; pixelSize: 10 } }
                        }
                    }

                    Row {
                        spacing: 5
                        Text {
                            text: "Open"
                            color: "#3a3a3a"
                            font { family: Theme.fontFamily; pixelSize: 10 }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 4; color: "#252525"
                            Text { anchors.centerIn: parent; text: "↵"; color: "#606060"; font { family: Theme.fontFamily; pixelSize: 10 } }
                        }
                    }
                }
            }
        }
    }
}
