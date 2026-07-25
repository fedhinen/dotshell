import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    signal brightnessUpdated()

    property int brightness: 0
    property int maxBrightness: 100
    property string backlightDevice: ""  // auto-detected

    readonly property real percent: maxBrightness > 0 ? brightness / maxBrightness : 0
    readonly property string icon: {
        if (percent >= 0.75) return String.fromCodePoint(0xf00e0)
        if (percent >= 0.50) return String.fromCodePoint(0xf00df)
        if (percent >= 0.25) return String.fromCodePoint(0xf00de)
        return String.fromCodePoint(0xf00dd)
    }

    // Step 1: detect which backlight device exists
    Process {
        id: detectBacklight
        command: ["sh", "-c", "ls /sys/class/backlight/ | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let dev = this.text.trim()
                if (dev.length > 0) {
                    root.backlightDevice = dev
                    getMax.running = true
                    getCurrent.running = true
                    monitor.running = true
                }
            }
        }
    }

    Process {
        id: getMax
        command: ["brightnessctl", "--device=" + root.backlightDevice, "max"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.maxBrightness = parseInt(this.text.trim()) || 100
        }
    }

    Process {
        id: getCurrent
        command: ["brightnessctl", "--device=" + root.backlightDevice, "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.brightness = parseInt(this.text.trim()) || 0
                root.brightnessUpdated()
            }
        }
    }

    Timer {
        id: brightnessRefresh
        interval: 50
        onTriggered: {
            getCurrent.running = false
            getCurrent.running = true
        }
    }

    Process {
        id: monitor
        command: ["inotifywait", "-m", "-e", "close_write",
            "/sys/class/backlight/" + root.backlightDevice + "/brightness"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                getCurrent.running = false
                brightnessRefresh.start()
            }
        }
    }

    // icon
    Text {
        text: root.icon
        color: Theme.fg
        font { family: Theme.nerdFontFamily; pixelSize: 10 }
    }

    // percentage
    Text {
        text: Math.round(root.percent * 100) + "%"
        color: Theme.fg
        font { family: Theme.fontFamily; pixelSize: 10; weight: 500 }
    }
}
