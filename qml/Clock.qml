import Quickshell
import QtQuick

Text {
  id: root

  property color accentColor: Theme.fg
  property int fontSize: 12

  text: Qt.formatDateTime(clock.date, "ddd MMM d h:mm AP")
  color: accentColor

  font {
    family: Theme.fontFamily
    weight: 500
    pixelSize: root.fontSize
  }
}
