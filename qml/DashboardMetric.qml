import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property string label
    required property string value
    required property string icon
    property color accent: Theme.info

    implicitHeight: 50
    radius: Theme.controlRadius
    color: Theme.oneBg2
    border.width: 1
    border.color: Theme.surfaceBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 7

        Text {
            text: root.icon
            color: root.accent
            font {
                family: Theme.nerdFontFamily
                pixelSize: 14
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.value
                color: Theme.fg
                font {
                    family: Theme.fontFamily
                    pixelSize: 11
                    weight: 600
                }
            }

            Text {
                text: root.label
                color: Theme.textMuted
                font {
                    family: Theme.fontFamily
                    pixelSize: 8
                }
            }
        }
    }
}
