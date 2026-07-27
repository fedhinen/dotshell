import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Session menu embedded in the shell's expanding top capsule. Actions require
// a two-second hold so tapping a control never changes the session accidentally.
Item {
    id: root

    property bool shown: false
    property int selectedIndex: 0
    property int heldKeyIndex: -1
    property real keyHoldProgress: 0

    signal lockRequested()

    visible: shown
    opacity: shown ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutExpo } }

    readonly property var actions: [
        { label: "Lock",     hint: "L", icon: "\uf023", color: Theme.color5, run: () => root.lock() },
        { label: "Suspend",  hint: "S", icon: "\uf9b1", color: Theme.color3, run: () => root.suspend() },
        { label: "Restart",  hint: "R", icon: "\uf021", color: Theme.color2, run: () => root.reboot() },
        { label: "Power off",hint: "P", icon: "\uf011", color: Theme.color1, run: () => root.poweroff() },
        { label: "Log out",  hint: "E", icon: "\uf2f5", color: Theme.color4, run: () => root.logout() }
    ]

    function show() {
        selectedIndex = 0
        cancelKeyHold()
        shown = true
        keyboard.forceActiveFocus()
    }

    function hide() {
        cancelKeyHold()
        shown = false
    }

    function toggle() {
        shown ? hide() : show()
    }

    function lock() {
        hide()
        lockRequested()
    }

    function suspend() {
        hide()
        lockRequested()
        suspendTimer.restart()
    }

    function reboot() {
        hide()
        rebootProcess.running = true
    }

    function poweroff() {
        hide()
        poweroffProcess.running = true
    }

    function logout() {
        hide()
        logoutProcess.running = true
    }

    function startKeyHold(index) {
        if (heldKeyIndex === index)
            return

        heldKeyIndex = index
        keyHoldProgress = 0
        keyHoldAnimation.restart()
        keyHoldTimer.restart()
    }

    function cancelKeyHold() {
        heldKeyIndex = -1
        keyHoldAnimation.stop()
        keyHoldProgress = 0
        keyHoldTimer.stop()
    }

    NumberAnimation {
        id: keyHoldAnimation
        target: root
        property: "keyHoldProgress"
        to: 1
        duration: 2000
    }

    Timer {
        id: keyHoldTimer
        interval: 2000
        onTriggered: {
            const index = root.heldKeyIndex
            root.cancelKeyHold()
            if (index >= 0)
                root.actions[index].run()
        }
    }

    // Give WlSessionLock a frame to create its surfaces before suspending.
    Timer {
        id: suspendTimer
        interval: 150
        onTriggered: suspendProcess.running = true
    }

    Process { id: suspendProcess; command: ["systemctl", "suspend"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    Process { id: logoutProcess; command: ["hyprctl", "dispatch", "exit"] }

    FocusScope {
        id: keyboard
        anchors.fill: parent
        focus: root.shown

        Keys.onPressed: (event) => {
            if (event.isAutoRepeat) {
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q || event.key === Qt.Key_X) {
                root.hide()
            } else if (event.key === Qt.Key_Left) {
                root.selectedIndex = (root.selectedIndex + root.actions.length - 1) % root.actions.length
            } else if (event.key === Qt.Key_Right) {
                root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.startKeyHold(root.selectedIndex)
            } else {
                const key = event.text.toUpperCase()
                for (let i = 0; i < root.actions.length; ++i) {
                    if (root.actions[i].hint === key) {
                        root.selectedIndex = i
                        root.startKeyHold(i)
                        break
                    }
                }
            }
            event.accepted = true
        }

        Keys.onReleased: (event) => {
            if (!event.isAutoRepeat)
                root.cancelKeyHold()
            event.accepted = true
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: actionButton
                        required property var modelData
                        required property int index
                        property real mouseHoldProgress: 0
                        readonly property real holdProgress: buttonMouse.pressed
                                                            ? mouseHoldProgress
                                                            : (root.heldKeyIndex === index ? root.keyHoldProgress : 0)

                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 88
                        radius: 14
                        clip: true
                        color: buttonMouse.pressed ? Theme.surfacePressed
                              : (buttonMouse.containsMouse || root.selectedIndex === index)
                                ? Theme.surfaceHover : Theme.black
                        border.width: 2
                        border.color: (buttonMouse.containsMouse || root.selectedIndex === index)
                                      ? modelData.color : Theme.lighterBlack
                        scale: buttonMouse.pressed ? 0.96 : 1

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * actionButton.holdProgress
                            radius: actionButton.radius
                            color: actionButton.modelData.color
                            opacity: 0.26
                        }

                        NumberAnimation {
                            id: mouseHoldAnimation
                            target: actionButton
                            property: "mouseHoldProgress"
                            to: 1
                            duration: 2000
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: actionButton.modelData.icon
                                color: actionButton.modelData.color
                                font { family: Theme.nerdFontFamily; pixelSize: 27 }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: actionButton.modelData.label
                                color: Theme.textPrimary
                                font { family: Theme.fontFamily; pixelSize: 10; weight: Font.Medium }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "[" + actionButton.modelData.hint + "]"
                                color: Theme.textMuted
                                font { family: Theme.fontFamily; pixelSize: 8 }
                            }
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            pressAndHoldInterval: 2000
                            onEntered: root.selectedIndex = actionButton.index
                            onPressed: {
                                actionButton.mouseHoldProgress = 0
                                mouseHoldAnimation.restart()
                            }
                            onReleased: {
                                mouseHoldAnimation.stop()
                                actionButton.mouseHoldProgress = 0
                            }
                            onCanceled: {
                                mouseHoldAnimation.stop()
                                actionButton.mouseHoldProgress = 0
                            }
                            onPressAndHold: actionButton.modelData.run()
                        }
                    }
                }
            }
        }
    }
}
