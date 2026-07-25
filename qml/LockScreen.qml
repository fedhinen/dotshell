import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool shown: false
    property int charactersEntered: 0
    property int prevPasswordLength: 0
    property string lockSymbol: Theme.lockScreenSymbol
    property string lockFailSymbol: Theme.lockScreenFailSymbol
    property color arcColor: Theme.transparent
    property int arcQuarter: 0
    property int activeHour: 12
    property bool usePast: false
    property string minutePhrase: "oclock"
    property bool authenticationStarted: false
    property bool submitRequested: false
    // WlSessionLockSurface is instantiated as a per-screen delegate, so its
    // children can't be reached with a compile-time `property alias` from
    // here or from WlSessionLock. Instead we keep the password text as a
    // plain property that the delegate mirrors, and use a signal to ask the
    // (possibly not-yet-existing) surface to focus its input.
    property string password: ""

    signal requestFocus()
    signal clearPasswordField()

    Timer {
        id: pamRestartTimer
        interval: 100
        onTriggered: root.startAuthentication()
    }

    function show() {
        shown = true
        resetState()
        updateWordClock(new Date())
        sessionLock.locked = true
        if (sessionLock.secure)
            startAuthentication()
    }

    function hide() {
        // A real session lock must only be released after successful PAM
        // authentication. Keep this function for IPC compatibility, but do
        // not allow it to bypass authentication.
        if (!sessionLock.locked)
            shown = false
    }

    function toggle() {
        if (!shown)
            lock()
    }

    function lock() {
        if (shown)
            return
        // Some compositors need a brief moment to finish tearing down the
        // previous lock surfaces before they'll accept a new session lock
        // request. Locking on the same tick as the previous unlock can be
        // silently ignored, which looks like "only the first lock works".
        Qt.callLater(root.show)
    }

    function resetState() {
        charactersEntered = 0
        prevPasswordLength = 0
        arcColor = Theme.transparent
        arcQuarter = 0
        password = ""
        clearPasswordField()
        authenticationStarted = false
        submitRequested = false
        lockUI.failed = false
        lockUI.authenticating = false
        lockUI.statusText = "Locked"
    }

    function startAuthentication() {
        if (authenticationStarted)
            return
        if (!sessionLock.secure)
            return
        authenticationStarted = true
        if (!pam.start()) {
            authenticationStarted = false
            lockUI.failed = true
            lockUI.statusText = "Authentication unavailable"
            return
        }
        requestFocus()
    }

    function authenticate() {
        try {
            if (lockUI.authenticating)
                return
            const password = root.password
            if (password.length === 0)
                return
            // PAM can deliver its password prompt asynchronously.
            if (!pam.responseRequired) {
                submitRequested = true
                lockUI.statusText = "Waiting for authentication prompt..."
                return
            }
            submitRequested = false
            lockUI.authenticating = true
            lockUI.failed = false
            lockUI.statusText = "Authenticating..."
            pam.respond(password)
            root.password = ""
            clearPasswordField()
        } catch (error) {
            lockUI.authenticating = false
            lockUI.failed = true
            lockUI.statusText = "Authentication error"
        }
    }

    function colorForStep(step) {
        const colors = [Theme.color1, Theme.color5, Theme.color4, Theme.color6, Theme.color2, Theme.color3]
        return colors[step % colors.length]
    }

    function keyAnimation(charInserted) {
        const direction = Math.max(0, (charactersEntered - 1) % 4)
        arcQuarter = direction
        if (charInserted) {
            arcColor = colorForStep(charactersEntered)
            return
        }

        if (charactersEntered <= 0) {
            arcColor = Theme.transparent
            arcQuarter = 0
        } else {
            arcColor = Qt.rgba(Theme.color7.r, Theme.color7.g, Theme.color7.b, 0.33)
        }
    }

    function updateWordClock(now) {
        const minute = now.getMinutes()
        let hour = now.getHours() % 12
        if (hour === 0)
            hour = 12

        if ((minute >= 0 && minute <= 2) || (minute >= 58 && minute <= 59)) {
            minutePhrase = "oclock"
        } else if ((minute >= 3 && minute <= 7) || (minute >= 53 && minute <= 57)) {
            minutePhrase = "five"
        } else if ((minute >= 8 && minute <= 12) || (minute >= 48 && minute <= 52)) {
            minutePhrase = "ten"
        } else if ((minute >= 13 && minute <= 17) || (minute >= 43 && minute <= 47)) {
            minutePhrase = "quarter"
        } else if ((minute >= 18 && minute <= 22) || (minute >= 38 && minute <= 42)) {
            minutePhrase = "twenty"
        } else if ((minute >= 23 && minute <= 27) || (minute >= 33 && minute <= 37)) {
            minutePhrase = "twentyfive"
        } else {
            minutePhrase = "half"
        }

        usePast = minute >= 3 && minute <= 32
        if (minute >= 33 && minute <= 57)
            usePast = false

        if (minute > 30)
            hour = (hour % 12) + 1
        activeHour = hour
    }

    function shouldHighlightWord(word) {
        if (word === "it" || word === "is")
            return true
        if (word === "past")
            return usePast && minutePhrase !== "oclock"
        if (word === "to")
            return !usePast && minutePhrase !== "oclock"
        if (word === "a")
            return minutePhrase === "quarter"
        if (word === "quarter")
            return minutePhrase === "quarter"
        if (word === "twenty")
            return minutePhrase === "twenty" || minutePhrase === "twentyfive"
        if (word === "five")
            return minutePhrase === "five" || minutePhrase === "twentyfive"
        if (word === "ten")
            return minutePhrase === "ten"
        if (word === "half")
            return minutePhrase === "half"
        if (word === "oclock")
            return minutePhrase === "oclock"
        return false
    }

    function shouldHighlightHour(word) {
        return parseInt(word) === activeHour
    }

    QtObject {
        id: lockUI
        property bool failed: false
        property bool authenticating: false
        property string statusText: "Locked"
    }

    PamContext {
        id: pam
        config: "login"

        onCompleted: (result) => {
            lockUI.authenticating = false
            if (result === PamResult.Success) {
                sessionLock.locked = false
                root.shown = false
                root.resetState()
            } else {
                root.authenticationStarted = false
                lockUI.failed = true
                lockUI.statusText = "Access Denied"
                root.requestFocus()
                pamRestartTimer.start()
            }
        }

        onError: (error) => {
            root.authenticationStarted = false
            lockUI.authenticating = false
            lockUI.failed = true
            lockUI.statusText = "Authentication error"
            root.requestFocus()
            pamRestartTimer.start()
        }

        onPamMessage: {
            if (pam.responseRequired) {
                lockUI.statusText = "Enter password"
                root.requestFocus()
                if (root.submitRequested)
                    root.authenticate()
            }
        }
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat: true
        onTriggered: root.updateWordClock(new Date())
    }

    WlSessionLock {
        id: sessionLock

        onSecureChanged: {
            if (secure)
                root.startAuthentication()
        }

        WlSessionLockSurface {
            id: lockSurface
            color: Theme.lockScreenBg

            Connections {
                target: root
                function onRequestFocus() { passwordInput.forceActiveFocus() }
                function onClearPasswordField() { passwordInput.clear() }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.lockScreenBg

                MouseArea {
                    anchors.fill: parent
                    onClicked: passwordInput.forceActiveFocus()
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.lockScreenContentSpacing

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 1
                        height: Theme.lockScreenTopPadding
                    }

                    Grid {
                        id: wordClockGrid
                        columns: 11
                        readonly property int rowCount: 10
                        width: columns * Theme.lockScreenGridCell
                            + (columns - 1) * Theme.lockScreenGridSpacing
                        height: rowCount * Theme.lockScreenGridCell
                            + (rowCount - 1) * Theme.lockScreenGridSpacing
                        columnSpacing: Theme.lockScreenGridSpacing
                        rowSpacing: Theme.lockScreenGridSpacing
                        Layout.alignment: Qt.AlignHCenter

                        readonly property var rowStrings: [
                            "ITLISASAMPM",
                            "ACQUARTERDC",
                            "TWENTYFIVEX",
                            "HALFSTENFTO",
                            "PASTERUNINE",
                            "ONESIXTHREE",
                            "FOURFIVETWO",
                            "EIGHTELEVEN",
                            "SEVENTWELVE",
                            "TENSEOCLOCK"
                        ]

                        Repeater {
                            model: 110
                            delegate: Text {
                                required property int index
                                readonly property int row: Math.floor(index / 11)
                                readonly property int col: index % 11
                                readonly property string line: wordClockGrid.rowStrings[row]
                                readonly property string ch: line.charAt(col)
                                readonly property bool active: {
                                    if (row === 0 && col >= 0 && col <= 1)
                                        return root.shouldHighlightWord("it")
                                    if (row === 0 && col >= 3 && col <= 4)
                                        return root.shouldHighlightWord("is")
                                    if (row === 1 && col >= 2 && col <= 8)
                                        return root.shouldHighlightWord("quarter")
                                    if (row === 2 && col >= 0 && col <= 5)
                                        return root.shouldHighlightWord("twenty")
                                    if (row === 2 && col >= 6 && col <= 9)
                                        return root.shouldHighlightWord("five")
                                    if (row === 3 && col >= 0 && col <= 3)
                                        return root.shouldHighlightWord("half")
                                    if (row === 3 && col >= 5 && col <= 7)
                                        return root.shouldHighlightWord("ten")
                                    if (row === 3 && col >= 9 && col <= 10)
                                        return root.shouldHighlightWord("to")
                                    if (row === 4 && col >= 0 && col <= 3)
                                        return root.shouldHighlightWord("past")
                                    if (row === 1 && col === 0)
                                        return root.shouldHighlightWord("a")
                                    if (row === 5 && col >= 0 && col <= 2)
                                        return root.shouldHighlightHour("1")
                                    if (row === 6 && col >= 8 && col <= 10)
                                        return root.shouldHighlightHour("2")
                                    if (row === 5 && col >= 6 && col <= 10)
                                        return root.shouldHighlightHour("3")
                                    if (row === 6 && col >= 0 && col <= 3)
                                        return root.shouldHighlightHour("4")
                                    if (row === 6 && col >= 4 && col <= 7)
                                        return root.shouldHighlightHour("5")
                                    if (row === 5 && col >= 3 && col <= 5)
                                        return root.shouldHighlightHour("6")
                                    if (row === 8 && col >= 0 && col <= 4)
                                        return root.shouldHighlightHour("7")
                                    if (row === 7 && col >= 0 && col <= 4)
                                        return root.shouldHighlightHour("8")
                                    if (row === 4 && col >= 7 && col <= 10)
                                        return root.shouldHighlightHour("9")
                                    if (row === 9 && col >= 0 && col <= 2)
                                        return root.shouldHighlightHour("10")
                                    if (row === 7 && col >= 5 && col <= 10)
                                        return root.shouldHighlightHour("11")
                                    if (row === 8 && col >= 5 && col <= 10)
                                        return root.shouldHighlightHour("12")
                                    if (row === 9 && col >= 5 && col <= 10)
                                        return root.shouldHighlightWord("oclock")
                                    return false
                                }

                                text: ch
                                width: Theme.lockScreenGridCell
                                height: Theme.lockScreenGridCell
                                color: active ? Theme.lockScreenActive : Theme.lockScreenDim
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                renderType: Text.NativeRendering
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.lockScreenGridFontSize
                                    weight: 700
                                }
                            }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: Theme.lockScreenArcSize
                        height: Theme.lockScreenArcSize

                        Rectangle {
                            id: arcCanvas
                            anchors.centerIn: parent
                            width: Theme.lockScreenArcSize
                            height: Theme.lockScreenArcSize
                            color: Theme.transparent
                            rotation: root.arcQuarter * 90
                            Behavior on rotation { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Canvas {
                                id: arcPainter
                                anchors.fill: parent

                                Connections {
                                    target: root
                                    function onArcColorChanged() { arcPainter.requestPaint() }
                                    function onArcQuarterChanged() { arcPainter.requestPaint() }
                                }

                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    if (root.arcColor === Theme.transparent)
                                        return
                                    const line = 8
                                    const radius = (width / 2) - line
                                    ctx.strokeStyle = root.arcColor.toString()
                                    ctx.lineWidth = line
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.arc(width / 2, height / 2, radius, 0, Math.PI / 2, false)
                                    ctx.stroke()
                                }
                            }
                        }

                        Text {
                            id: lockIcon
                            anchors.centerIn: parent
                            width: 80
                            height: 80
                            // Material Icons: U+E897 is the filled lock glyph.
                            text: lockUI.failed ? root.lockFailSymbol : root.lockSymbol
                            color: Theme.lockScreenActive
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: Theme.lockScreenIconFont
                            font.pixelSize: Theme.lockScreenIconSize
                        }
                    }

                    TextInput {
                        id: passwordInput
                        width: 1
                        height: 1
                        opacity: 0
                        focus: root.shown
                        echoMode: TextInput.Password

                        onTextChanged: {
                            const delta = text.length - root.prevPasswordLength
                            if (delta > 0) {
                                root.charactersEntered += delta
                                root.keyAnimation(true)
                            } else if (delta < 0) {
                                root.charactersEntered = Math.max(0, root.charactersEntered + delta)
                                root.keyAnimation(false)
                            }
                            root.prevPasswordLength = text.length
                            root.password = text
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.authenticate()
                                // Avoid TextInput's default Enter handling after submitting.
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                // Escape cannot unlock a WlSessionLock.
                                passwordInput.clear()
                                event.accepted = true
                            }
                        }

                        onAccepted: root.authenticate()
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: lockUI.statusText
                        color: lockUI.failed ? Theme.color7 : Theme.lockScreenHint
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
