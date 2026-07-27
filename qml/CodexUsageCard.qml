import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool loggedIn: false
    property bool loading: false
    property bool stale: false
    property int consumedPercent: 0
    property int remainingPercent: 0
    property string resetsAt: ""
    property string errorText: ""

    function resetText() {
        if (!root.resetsAt) return ""
        const reset = new Date(root.resetsAt)
        if (isNaN(reset.getTime())) return ""
        return "Reinicia " + Qt.formatDateTime(reset, "ddd HH:mm")
    }

    implicitHeight: 48
    radius: Theme.controlRadius
    color: Theme.oneBg2
    border.width: 1
    border.color: Theme.surfaceBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 9

        Text {
            text: "󰚩"
            color: root.loggedIn ? Theme.info : Theme.textMuted
            font {
                family: Theme.nerdFontFamily
                pixelSize: 15
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "CODEX"
                    color: Theme.fg
                    font {
                        family: Theme.fontFamily
                        pixelSize: 9
                        weight: 600
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.loading ? "Actualizando..."
                        : !root.loggedIn ? (root.errorText || "Sin sesión")
                        : root.remainingPercent + "% restante"
                    color: root.stale ? Theme.warning : Theme.textSecondary
                    font {
                        family: Theme.fontFamily
                        pixelSize: 8
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Theme.grey

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, root.consumedPercent)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.stale ? Theme.warning : Theme.info
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.minimumWidth: 92

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.loggedIn ? root.consumedPercent + "% usado" : "—"
                color: Theme.fg
                font {
                    family: Theme.fontFamily
                    pixelSize: 9
                    weight: 600
                }
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.resetText()
                color: Theme.textMuted
                font {
                    family: Theme.fontFamily
                    pixelSize: 7
                }
            }
        }
    }
}
