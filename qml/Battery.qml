import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property int fontSize: 10
    property color fg: Theme.fg

    property var battery: box.battery
    property bool charging: box.charging

    readonly property bool hasBattery: battery && battery.percentage !== undefined
    readonly property int batteryLevel: Math.max(0, Math.min(100, Math.round(((battery && battery.percentage !== undefined) ? battery.percentage : 0) * 100)))

    readonly property color white: Theme.white
    readonly property color happyColor: Theme.color2
    readonly property color sadColor: Theme.color1
    readonly property color okColor: Theme.color3
    readonly property color chargingColor: Theme.color6

    readonly property color batteryColor: charging ? chargingColor
        : batteryLevel <= 15 ? sadColor
        : batteryLevel <= 30 ? okColor
        : happyColor

    visible: hasBattery
    spacing: 5

    Item {
        implicitWidth: 30
        implicitHeight: 16

        Rectangle {
            id: batteryBody
            x: 0
            y: 1
            width: 30
            height: 14
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: root.white
        }

        Rectangle {
            x: batteryBody.x + 2
            y: batteryBody.y + 2
            width: Math.max(0, (batteryBody.width - 4) * (root.batteryLevel / 100))
            height: batteryBody.height - 4
            radius: 1
            color: root.batteryColor
        }

        Text {
            visible: root.charging
            anchors.centerIn: batteryBody
            text: String.fromCodePoint(0xf140b)
            color: root.white
            font.family: Theme.nerdFontFamily
            font.pixelSize: root.fontSize
        }
    }

    Text {
        text: root.batteryLevel + "%"
        color: root.fg
        font.family: Theme.fontFamily
        font.weight: 500
        font.pixelSize: root.fontSize
    }
}
