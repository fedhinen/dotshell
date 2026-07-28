import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
  id: root
  property bool active: false
  property var notif: null
  property int maxSummaryLines: 2
  property int maxBodyLines: 6

  anchors.centerIn: parent
  implicitWidth: notificationRow.implicitWidth
  implicitHeight: notificationRow.implicitHeight
  width: implicitWidth
  height: implicitHeight
  opacity: active ? 1 : 0
  visible: opacity > 0
  Behavior on opacity { NumberAnimation { duration: 150 } }

  RowLayout {
    id: notificationRow
    anchors.centerIn: parent
    spacing: 10

    Text {
      text: String.fromCodePoint(0xf0f3)
      color: Theme.fg
      font { family: Theme.nerdFontFamily; pixelSize: 14 }
      visible: notifIcon.status !== Image.Ready
    }

    Image {
      id: notifIcon
      width: 22
      height: 22
      fillMode: Image.PreserveAspectCrop
      source: {
        if (root.notif && root.notif.image) return root.notif.image
        if (root.notif && root.notif.appIcon) {
          return root.notif.appIcon.startsWith("/") 
            ? "file://" + root.notif.appIcon 
            : "image://icon/" + root.notif.appIcon
        }
        return ""
      }
      sourceSize: Qt.size(22, 22)
      visible: status === Image.Ready
    }

    ColumnLayout {
      Layout.preferredWidth: 220
      Layout.maximumWidth: 220
      spacing: 2

      Text {
        text: root.notif ? root.notif.summary : ""
        color: Theme.fg
        font { family: Theme.fontFamily; pixelSize: 10; weight: 600 }
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: root.maxSummaryLines
        Layout.fillWidth: true
      }

      Text {
        text: root.notif ? root.notif.body : ""
        color: Theme.textSecondary
        font { family: Theme.fontFamily; pixelSize: 9 }
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: root.maxBodyLines
        Layout.fillWidth: true
        visible: text !== ""
      }
    }
  }

  // Chrome includes a "default" action that opens the originating page.
  // Treating the whole popup as that action preserves native-notification
  // behavior without adding controls to the compact pill.
  MouseArea {
    anchors.fill: parent
    enabled: root.notif && root.notif.actions && root.notif.actions.length > 0
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
      for (let i = 0; i < root.notif.actions.length; i++) {
        const action = root.notif.actions[i]
        if (action.identifier === "default") {
          action.invoke()
          return
        }
      }
    }
  }
}
