import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Services.Notifications

ShellRoot {

  ColorTemperature {
      id: colorTemperature
  }

  BatteryProfiles {
      id: powerProfiles
  }

  IpcHandler {
      target: "colorTemperature"
      function toggle(): void { colorTemperature.toggle() }
      function warmer(): void { colorTemperature.change(-250) }
      function cooler(): void { colorTemperature.change(250) }
  }

  IpcHandler {
      target: "launcher"
      function toggle(): void { launcherWindow.shown ? launcherWindow.hide() : launcherWindow.show() }
      function show(): void { launcherWindow.show() }
      function hide(): void { launcherWindow.hide() }
  }

  GlobalShortcut {
      name: "launcher"
      description: "Toggle app launcher"
      onPressed: launcherWindow.shown ? launcherWindow.hide() : launcherWindow.show()
  }

  Launcher {
      id: launcherWindow
  }

  IpcHandler {
      target: "cliphist"
      function toggle(): void { powerMenu.hide(); box.controlCenter = false; box.miniDashboard = false; box.cliphistOpen = !box.cliphistOpen }
      function show(): void { powerMenu.hide(); box.controlCenter = false; box.miniDashboard = false; box.cliphistOpen = true }
      function hide(): void { box.cliphistOpen = false }
  }

  IpcHandler {
      target: "controlCenter"
      function toggle(): void { powerMenu.hide(); box.controlCenter = !box.controlCenter; box.miniDashboard = false; box.cliphistOpen = false }
      function show(): void { powerMenu.hide(); box.controlCenter = true; box.miniDashboard = false; box.cliphistOpen = false }
      function hide(): void { box.controlCenter = false }
  }

  IpcHandler {
      target: "miniDashboard"
      function toggle(): void { powerMenu.hide(); box.controlCenter = false; box.miniDashboard = !box.miniDashboard; box.cliphistOpen = false }
      function show(): void { powerMenu.hide(); box.controlCenter = false; box.miniDashboard = true; box.cliphistOpen = false }
      function hide(): void { box.miniDashboard = false }
  }

  IpcHandler {
      target: "lockscreen"
      function toggle(): void { lockscreen.toggle() }
      function show(): void { lockscreen.show() }
      function hide(): void { lockscreen.hide() }
      function lock(): void { lockscreen.lock() }
  }

  IpcHandler {
      target: "powerMenu"
      function toggle(): void {
        box.controlCenter = false
        box.miniDashboard = false
        box.cliphistOpen = false
        powerMenu.toggle()
      }
      function show(): void {
        box.controlCenter = false
        box.miniDashboard = false
        box.cliphistOpen = false
        powerMenu.show()
      }
      function hide(): void { powerMenu.hide() }
  }

  property string bg: Theme.bg
  property string fg: Theme.fg
  property string fontFamily: Theme.fontFamily
  property int avatarSize: 48
  property int buttonSize: 20
  property string buttonBg: Theme.oneBg2
  property string buttonHoverBg: Theme.white
  property int buttonHoverSpeed: 120
  property int buttonctlRadius: 6
  property string dashboardCpu: "--%"
  property string dashboardRam: "--%"
  property string dashboardDisk: "--%"
  property bool codexLoggedIn: false
  property bool codexUsageLoading: false
  property bool codexUsageStale: false
  property int codexConsumedPercent: 0
  property int codexRemainingPercent: 0
  property string codexResetsAt: ""
  property string codexUsageError: ""

  property bool notifFullscreenMode: false
  property bool fullscreenActive: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.fullscreen

  // osd ui
  property int osdInWidth: 120
  property real osdInHeight: 3.7
  property int osdBarRadius: 2
  property int osdSpeed: 60 // how fast bar fill/unfill
  property int osdWidth: 220
  property int osdHeight: 40
  property int controlCenterAutoHideDuration: 2500

  readonly property int notifMaxHeight: 97

  // media player related
  property bool mediaAutoOpened: false

  PanelWindow {
    id: barWindow

    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.keyboardFocus: (box.cliphistOpen || powerMenu.shown)
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    implicitHeight: 482

    anchors {
      top: true
      left: true
      right: true
    }

    margins {
      top: Config.pillTopMargin
    }

    // fixed gap of the active window for the top bar
    exclusiveZone: Config.pillBottomMargin
    color: "transparent"

    // Mask input to only the capsule
    mask: Region {
      Region {
        intersection: Intersection.Combine
        x: Math.floor(box.x); y: Math.floor(box.y)
        width: Math.ceil(box.width); height: Math.ceil(box.height)
      }
      Region {
        intersection: Intersection.Combine
        x: Math.floor(calendarPopup.x); y: Math.floor(calendarPopup.y)
        width: calendarPopup.shown ? Math.ceil(calendarPopup.width) : 0
        height: calendarPopup.shown ? Math.ceil(calendarPopup.height) : 0
      }
      Region {
        intersection: Intersection.Combine
        x: Math.floor(weatherPopupBox.x); y: Math.floor(weatherPopupBox.y)
        width: weatherPopupBox.shown ? Math.ceil(weatherPopupBox.width) : 0
        height: weatherPopupBox.shown ? Math.ceil(weatherPopupBox.height) : 0
      }
    }

    // main box for the dynamic view
    Rectangle {
      id: box
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      clip: true

      property bool hovered: false
      property bool miniDashboard: false
      property bool controlCenter: false
      property bool cliphistOpen: false
      property bool volumeActive: false
      property bool brightnessActive: false
      property bool batteryCharging: false

      property var battery: UPower.displayDevice
      property bool charging: battery.state === UPowerDeviceState.Charging

      readonly property color batteryIconColor: box.charging || box.batteryLevel > 30 ? Theme.success
         : box.batteryLevel <= 15 ? Theme.dangerBright
         : Theme.warning

      readonly property int batteryLevel: Math.round(battery.percentage * 100)

      // get battery icon according percentage
      readonly property string batteryIcon: {
        const icons = [0xf0083, 0xf007a, 0xf007d, 0xf007c, 0xf007d, 0xf007e, 0xf007f, 0xf0082, 0xf0081, 0xf0079]
        const base = String.fromCodePoint(icons[Math.min(Math.floor(batteryLevel / 10), 9)])
        return charging ? base + String.fromCodePoint(0xf140b) : base
      }

      onChargingChanged: {
        box.batteryCharging = true
        batteryStatusHideTimer.restart()
        console.log("charging:", box.charging, "level:", box.batteryLevel)
      }

      property string accent: Theme.accent

      // control center UI
      property real ccButtonBorderWidth: 1
      property string ccButtonBorderColor: Theme.oneBg3
      property int ccButtonWidth: 112
      property int ccButtonHeight: 35
      property int ccButtonRadius: 10
      property string ccButtonBgOff: Theme.oneBg
      property string ccButtonFgOff: Theme.lightGrey
      property int sliderHeight: 4
      property int sliderRadius: 4
      property string sliderColor: Theme.white
      property int mprisControlsIconSize: 20

      Timer { id: volumeHideTimer; interval: Config.osdDuration; onTriggered: box.volumeActive = false }
      Timer { id: brightnessHideTimer; interval: Config.osdDuration; onTriggered: box.brightnessActive = false }
      Timer { id: batteryStatusHideTimer; interval: Config.osdDuration; onTriggered: box.batteryCharging = false }
      Timer {
        id: controlCenterHideTimer
        interval: controlCenterAutoHideDuration
        repeat: false
        onTriggered: {
          if (box.controlCenter && !box.hovered && !mediaAutoOpened) {
            box.controlCenter = false
          }
        }
      }
      Timer { id: brightnessThrottle; interval: 80; repeat: false }

      Process { id: brightnessSetProc; running: false }

      onImplicitHeightChanged: {
          heightAnim.stop()
          heightAnim.to = implicitHeight
          heightAnim.duration = mediaAutoOpened ? 650 : 550
          heightAnim.start()
      }

      onHoveredChanged: {
        if (hovered) {
          controlCenterHideTimer.stop()
          return
        }

        if (controlCenter && !mediaAutoOpened) {
          controlCenterHideTimer.restart()
        }
      }

      onControlCenterChanged: {
        if (!controlCenter || mediaAutoOpened || hovered) {
          controlCenterHideTimer.stop()
          return
        }

        controlCenterHideTimer.restart()
      }

      readonly property int notifBump: notificationModule.notifications.length > 0
        ? Math.min(notifList.contentHeight + 40, 130) : 0

      implicitWidth: powerMenu.shown ? 510
                     : batteryCharging ? osdWidth
                     : (notificationModule.active && !notifFullscreenMode) ? 280
                     : controlCenter && mediaAutoOpened ? 380
                     : controlCenter ? 390
                     : volumeActive ? osdWidth
                     : brightnessActive ? osdWidth
                     : cliphistOpen ? 450
                     : miniDashboard ? 420
                     : row.implicitWidth + (hovered ? 68 : 56)

      implicitHeight: powerMenu.shown ? 122
                  : batteryCharging ? osdHeight
                  : (notificationModule.active && !notifFullscreenMode) ? 50
                  : controlCenter && mprisModule.hasPlayer && mediaAutoOpened
                      ? 124
                  : controlCenter && mprisModule.hasPlayer
                      ? ((colorTemperature.enabled ? 316 : 296) + notifBump)
                  : controlCenter
                      ? ((colorTemperature.enabled ? 194 : 174) + notifBump)
                  : volumeActive ? osdHeight
                  : brightnessActive ? osdHeight
                  : cliphistOpen ? 270
                  : miniDashboard ? 273
                  : row.implicitHeight + (hovered ? 10 : 10)

      radius: powerMenu.shown ? 25 : notificationModule.active ? 99 : cliphistOpen ? 25 : controlCenter && mprisModule.hasPlayer ? 23 : controlCenter && (notificationModule.notifications.length > 0) ? 25 : 20
      color: controlCenter && mprisModule.hasPlayer ? Theme.black : bg

      onMiniDashboardChanged: {
        if (!miniDashboard) { calendarPopup.shown = false; weatherPopupBox.shown = false }
        if (miniDashboard) {
          codexUsageLoading = true
          codexUsageProc.running = false
          codexUsageProc.running = true
        }
      }

      Behavior on implicitWidth { NumberAnimation { duration: 225; easing.type: Easing.OutExpo } }
      NumberAnimation { id: heightAnim; target: box; property: "height"; easing.type: Easing.OutExpo }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onEntered: box.hovered = true
        onExited: box.hovered = false

        onClicked: (mouse) => {

          if (box.controlCenter) {
            if (mouse.button === Qt.LeftButton)
                box.controlCenter = false
            return
          }

          if (powerMenu.shown) {
            if (mouse.button === Qt.LeftButton)
              powerMenu.hide()
            return
          }

          if (box.cliphistOpen) {
            if (mouse.button === Qt.MiddleButton) {
              box.cliphistOpen = false
            }
            return
          }

          if (box.miniDashboard) {
            if (mouse.button === Qt.RightButton) {
              box.miniDashboard = false
            }
            return
          }

          if (mouse.button === Qt.LeftButton) {
            powerMenu.hide()
            box.controlCenter = !box.controlCenter
            mediaAutoOpened = false
            mediaPopupHideTimer.stop()
          }

          if (mouse.button === Qt.MiddleButton) {
            powerMenu.hide()
            mediaAutoOpened = false
            box.cliphistOpen = !box.cliphistOpen
          }

          if (mouse.button === Qt.RightButton) {
              powerMenu.hide()
              mediaAutoOpened = false
              box.miniDashboard = !box.miniDashboard
          }
        }
      }

      Brightness {
          id: brightnessModule
          visible: false
          onBrightnessUpdated: {
              box.brightnessActive = true
              brightnessHideTimer.restart()
          }
      }

      // modulues in bar
      RowLayout {
        id: row
        anchors.centerIn: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 13
        opacity: !powerMenu.shown && !box.cliphistOpen && !notificationModule.active && !box.controlCenter && !box.miniDashboard && !box.volumeActive && !box.brightnessActive && !box.batteryCharging ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 100 } }

        Battery {}
        Volume {
          id: volumeModule
          onVolumeChanged: {
            box.volumeActive = true
            volumeHideTimer.restart()
            }
        }
        Workspaces {}
        Network {}
        Clock {}
        SystemTray {
          parentWindow: barWindow
          menuAnchor: box
        }
      }

      // volume
      OsdBar {
          active: box.volumeActive && !powerMenu.shown && !box.controlCenter
          icon: volumeModule.icon
          iconColor: volumeModule.muted ? volumeModule.mutedFg : Theme.fg
          percent: volumeModule.vol / 100
          muted: volumeModule.muted
          barWidth: volumeModule.muted ? 90 : 110
          valueText: volumeModule.muted ? "muted" : volumeModule.vol + "%"
      }

      // brightness
      OsdBar {
          active: box.brightnessActive && !powerMenu.shown && !box.volumeActive && !box.controlCenter
          icon: brightnessModule.icon
          percent: brightnessModule.percent
          valueText: Math.round(brightnessModule.percent * 100) + "%"
          barWidth: 100
      }

      // battery
      OsdBar {
        active: box.batteryCharging && !powerMenu.shown && !box.volumeActive && !box.brightnessActive
        icon: box.batteryIcon
        iconColor: box.batteryIconColor
        valueText: box.charging ? "Charging" : "Charging stopped"
        barWidth: 0
        spacing: 5 // gap between battery icon and text
      }

      // power menu
      Item {
        anchors.centerIn: parent
        width: box.implicitWidth - (Theme.panelPadding * 2)
        height: powerMenu.shown ? box.implicitHeight - (Theme.panelPadding * 2) : 0
        opacity: powerMenu.shown ? 1 : 0
        visible: opacity > 0

        PowerMenu {
          id: powerMenu
          anchors.fill: parent
          onLockRequested: lockscreen.lock()
        }
      }

      // notification
      NotificationPopup {
        active: notificationModule.active && !powerMenu.shown && !notifFullscreenMode && !box.volumeActive && !box.batteryCharging && !box.brightnessActive
        notif: notificationModule.current
      }

      // cliphist opens on middle click
      Item {
        anchors.centerIn: parent
        width: box.implicitWidth - (Theme.panelPadding * 2)
        height: box.cliphistOpen ? box.implicitHeight - (Theme.panelPadding * 2) : 0
        opacity: box.cliphistOpen && !notificationModule.active && !box.volumeActive && !box.brightnessActive && !box.batteryCharging && !box.controlCenter ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          SequentialAnimation {
            PauseAnimation { duration: box.cliphistOpen ? 15 : 0 }
            NumberAnimation { duration: 150; easing.type: Easing.OutExpo }
          }
        }

        Cliphist {
          id: cliphistPanel
          shown: box.cliphistOpen
          anchors.fill: parent
          onCloseRequested: box.cliphistOpen = false
        }
      }

      // control center opens on left click
      Item {
        anchors.centerIn: parent
        width: box.implicitWidth - (Theme.panelPadding * 2)
        opacity: box.controlCenter && !box.batteryCharging && !notificationModule.active ? 1 : 0
        visible: opacity > 0
        height: box.controlCenter && !box.batteryCharging
            ? box.implicitHeight - (Theme.panelPadding * 2) : 0

        Behavior on opacity {
          SequentialAnimation {
            PauseAnimation { duration: box.controlCenter ? 15 : 0 }
            NumberAnimation { duration: 150; easing.type: Easing.OutExpo }
          }
        }

        // media player
        MediaPlayer {
          margin: box.controlCenter && mediaAutoOpened ? 5 : 14
          artistFontSize: box.controlCenter && mediaAutoOpened ? 10 : 9
          artistFontWeight: box.controlCenter && mediaAutoOpened ? 500 : 400
          artistFontColor: box.controlCenter && mediaAutoOpened ? Theme.greyFg2 : Theme.greyFg
          color: box.controlCenter && mediaAutoOpened ? Theme.black : Theme.oneBg
          radius: box.controlCenter && mprisModule.hasPlayer ? 16 : 25
          border.width: box.controlCenter && mediaAutoOpened ? 0 : 1
        }

        // control center buttons
        CcButtons {
          buttonBorderColor: box.ccButtonBorderColor
          buttonBorderWidth: box.ccButtonBorderWidth
          buttonWidth: box.ccButtonWidth
          buttonHeight: box.ccButtonHeight
          buttonRadius: box.ccButtonRadius
          buttonBgOff: box.controlCenter && !mprisModule.hasPlayer ? Theme.color0 : box.ccButtonBgOff
          buttonFgOff: box.controlCenter && !mprisModule.hasPlayer ? Theme.greyFg2 : box.ccButtonFgOff
          controlCenterOpen: box.controlCenter
          mediaAutoOpened: mediaAutoOpened
          hasPlayer: mprisModule.hasPlayer
          playerHeight: box.ccButtonHeight
        } 

        // sliders
        Column {
          id: sliderColumn
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.topMargin: mprisModule.hasPlayer ? box.ccButtonHeight + 137 : 50
          anchors.leftMargin: Theme.contentInset
          anchors.rightMargin: Theme.contentInset
          spacing: Theme.contentInset
          visible: !mediaAutoOpened

          // volume
          RowLayout {
            width: parent.width
            spacing: 14

            Text {
              text: volumeModule.icon
              color: volumeModule.muted ? Theme.dangerBright : Theme.fg
              font.family: Theme.nerdFontFamily
              font.pixelSize: 13
              anchors.leftMargin: 10
            }

            Rectangle {
              Layout.fillWidth: true
              height: box.sliderHeight
              radius: box.sliderRadius
              color: Theme.grey

              Rectangle {
                width: parent.width * (volumeModule.vol / 100)
                height: parent.height
                radius: box.sliderRadius
                color: box.sliderColor
                Behavior on width { NumberAnimation { duration: 60 } }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                  volumeModule.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                }
                onPositionChanged: (mouse) => {
                  if (pressed)
                    volumeModule.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                }
              }
            }

            Text {
              text: volumeModule.muted ? "muted" : volumeModule.vol + "%"
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 10
              Layout.minimumWidth: 35
            }
          }

          // brightness
          RowLayout {
            width: parent.width
            spacing: 14

            Text {
              text: brightnessModule.icon
              color: Theme.fg
              font.family: Theme.nerdFontFamily
              font.pixelSize: 13
            }

            Rectangle {
              Layout.fillWidth: true
              height: box.sliderHeight
              radius: box.sliderRadius
              color: Theme.grey

              Rectangle {
                width: parent.width * brightnessModule.percent
                height: parent.height
                radius: box.sliderRadius
                color: box.sliderColor
                Behavior on width { NumberAnimation { duration: 60 } }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                  let pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100)
                  brightnessSetProc.command = ["brightnessctl", "set", pct + "%"]
                  brightnessSetProc.running = false
                  brightnessSetProc.running = true
                }
                onPositionChanged: (mouse) => {
                  if (pressed && !brightnessThrottle.running) {
                    let pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100)
                    brightnessSetProc.command = ["brightnessctl", "set", pct + "%"]
                    brightnessSetProc.running = false
                    brightnessSetProc.running = true
                    brightnessThrottle.start()
                  }
                }
              }
            }

            Text {
              text: Math.round(brightnessModule.percent * 100) + "%"
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 10
              Layout.minimumWidth: 35
            }
          }

          // color temperature, shown only while enabled
          RowLayout {
            width: parent.width
            spacing: 14
            visible: colorTemperature.enabled

            Text {
              text: "\uf2c9"
              color: Theme.warning
              font { family: Theme.nerdFontFamily; pixelSize: 13 }
            }

            Rectangle {
              Layout.fillWidth: true
              height: box.sliderHeight
              radius: box.sliderRadius
              color: Theme.grey

              Rectangle {
                width: parent.width * ((colorTemperature.temperature - colorTemperature.minimum)
                    / (colorTemperature.maximum - colorTemperature.minimum))
                height: parent.height
                radius: box.sliderRadius
                color: Theme.warning
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => colorTemperature.setTemperature(
                    colorTemperature.minimum + (mouse.x / width)
                    * (colorTemperature.maximum - colorTemperature.minimum))
                onPositionChanged: (mouse) => {
                  if (pressed) colorTemperature.setTemperature(
                      colorTemperature.minimum + Math.max(0, Math.min(1, mouse.x / width))
                      * (colorTemperature.maximum - colorTemperature.minimum))
                }
              }
            }

            Text {
              text: colorTemperature.temperature + "K"
              color: Theme.fg
              font { family: Theme.fontFamily; pixelSize: 10 }
              Layout.minimumWidth: 42
            }
          }

          // power profiles section
          Rectangle {
            width: parent.width
            height: 59
            radius: Theme.controlRadius
            color: Theme.oneBg
            border.width: 1
            border.color: Theme.oneBg3

            Text {
              anchors { top: parent.top; left: parent.left; margins: Theme.cardPadding }
              text: powerProfiles.daemonAvailable ? "Perfil de energía"
                  : powerProfiles.errorMessage
              color: powerProfiles.daemonAvailable ? Theme.fg : Theme.dangerBright
              font { family: Theme.fontFamily; pixelSize: 10; weight: 500 }
            }

            RowLayout {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 7 }
              spacing: 5

              Repeater {
                model: [
                  { id: "power-saver", label: "Ahorro", icon: "\uf06c" },
                  { id: "balanced", label: "Normal", icon: "\uf24e" },
                  { id: "performance", label: "Rendimiento", icon: "\uf0e7" }
                ]

                Rectangle {
                  required property var modelData
                  readonly property bool profileSupported: powerProfiles.supported(modelData.id)
                  Layout.fillWidth: true
                  height: 24
                  radius: 7
                  color: powerProfiles.activeProfile === modelData.id ? Theme.oneBg3 : "transparent"
                  opacity: profileSupported ? 1 : 0.35

                  Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                      text: modelData.icon
                      color: powerProfiles.activeProfile === modelData.id
                          ? Theme.warning : Theme.greyFg2
                      font { family: Theme.nerdFontFamily; pixelSize: 9 }
                    }

                    Text {
                      text: modelData.label
                      color: powerProfiles.activeProfile === modelData.id
                          ? Theme.white : Theme.greyFg2
                      font { family: Theme.fontFamily; pixelSize: 9 }
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: parent.profileSupported
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: powerProfiles.setProfile(modelData.id)
                  }
                }
              }
            }
          }
        } 

      // notifications stack popped header
      Rectangle {
        id: headerBar
        anchors.top: notifBox.top
        anchors.topMargin: -21
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 10
        height: 35
        topLeftRadius: 13
        topRightRadius: 13
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Theme.oneBg3
        visible: notifBox.visible
        z: 0

        Item {
          anchors.fill: parent

          Text {
            text: "Notifications (" + notificationModule.notifications.length + ")"
            color: Theme.white
            font { family: Theme.fontFamily; pixelSize: 9; weight: 400 }
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: Theme.cardPadding
            anchors.topMargin: 4
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 60
            height: 16
            radius: 10
            color: clearAllHover.containsMouse ? Theme.black : Theme.color0
            Behavior on color { ColorAnimation { duration: 100 } }
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 3
            anchors.rightMargin: Theme.cardPadding

            Text {
              text: "Clear all"
              color: Theme.white
              font { family: Theme.fontFamily; pixelSize: 8; weight: 300 }
              anchors.centerIn: parent
            }

            MouseArea {
              id: clearAllHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: notificationModule.clearAll()
            }
          }
        }
      }

      // notification list stack
      Rectangle {
        id: notifBox
        anchors.top: sliderColumn.bottom
        anchors.topMargin: 32
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 10
        height: Math.min(notifList.contentHeight + 7, notifMaxHeight)
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 13
        bottomRightRadius: 13
        color: Theme.oneBg
        visible: notificationModule.notifications.length > 0 && box.controlCenter && !mediaAutoOpened
        clip: true
        border.width: 1
        border.color: Theme.oneBg3
        z: 1

        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        ListView {
          id: notifList
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.topMargin: 5
          anchors.leftMargin: 5
          anchors.rightMargin: 5
          height: Math.min(contentHeight, notifMaxHeight)
          spacing: 6
          model: notificationModule.notificationsReversed
          clip: true
          interactive: contentHeight > height
          flickDeceleration: 3000
          maximumFlickVelocity: 2500
          boundsBehavior: Flickable.StopAtBounds

          // cache delegates instead of recreating on scroll
          cacheBuffer: 200
          reuseItems: true

          ScrollBar.vertical: ScrollBar {
            id: notifScrollBar
            policy: ScrollBar.AlwaysOff
            visible: notifList.contentHeight > notifList.height
            width: 10
            anchors.rightMargin: 10
            z: 20
            contentItem: Rectangle {
              implicitWidth: 8
              radius: 10
              color: notifScrollBar.pressed ? Theme.lightGrey
                   : scrollHover.hovered ? Theme.greyFg2
                   : Theme.grey
              Behavior on color { ColorAnimation { duration: 100 } }
              HoverHandler { id: scrollHover }
            }
          }

          // add/append notifications in the stack
          delegate: Item {
            id: notifDelegate
            width: ListView.view.width
            height: contentColumn.implicitHeight + 7

            // glyph (nerd font) bell icon
            Text {
              id: bellIcon
              text: String.fromCodePoint(0xf0f3)
              color: Theme.fg
              font { family: Theme.nerdFontFamily; pixelSize: 16 }
              visible: notifIcon.status !== Image.Ready
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.topMargin: 10
              anchors.leftMargin: 16
            }

            // custom appicon
            Image {
              id: notifIcon
              width: 20
              height: 20
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              source: {
                if (modelData.image) return modelData.image
                if (modelData.appIcon) {
                  return modelData.appIcon.startsWith("/")
                    ? "file://" + modelData.appIcon
                    : "image://icon/" + modelData.appIcon
                }
                return ""
              }
              sourceSize: Qt.size(20, 20)
              visible: status === Image.Ready
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.topMargin: 10
              anchors.leftMargin: 15
            }

            ColumnLayout {
              id: contentColumn
              anchors.fill: parent
              anchors.leftMargin: 50
              anchors.rightMargin: 3
              anchors.bottomMargin: 20
              spacing: 1

              Item {
                Layout.fillHeight: true
                Layout.topMargin: 8
                visible: !bodyText.visible
              }

              // heading / summary
              RowLayout {
                Layout.fillWidth: true

                Text {
                  text: modelData.summary
                  color: Theme.fg
                  font { family: Theme.fontFamily; pixelSize: 11; weight: 600 }
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: modelData.receivedTime ? Qt.formatTime(modelData.receivedTime, "hh:mm") : ""
                  color: Theme.greyFg2
                  font { family: Theme.fontFamily; pixelSize: 8 }
                  Layout.bottomMargin: 5
                }

                // close button
                Rectangle {
                  Layout.preferredWidth: 22
                  Layout.preferredHeight: 22
                  radius: 99
                  color: dismissHover.containsMouse ? Theme.grey : "transparent"
                  Behavior on color { ColorAnimation { duration: 100 } }

                  Text {
                    text: ""
                    color: dismissHover.containsMouse ? Theme.white : Theme.greyFg
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }

                  MouseArea {
                    id: dismissHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notificationModule.dismiss(modelData)
                  }
                }
              }

              // description / body
              Text {
                id: bodyText
                text: modelData.body
                color: Theme.greyFg2
                font { family: Theme.fontFamily; pixelSize: 8; weight: 300 }
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                visible: text !== ""
              }

              Item {
                Layout.fillHeight: true
                Layout.bottomMargin: 6
                visible: !bodyText.visible
              }
            }

            // divider
            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: 1
              color: Theme.grey
              visible: index < notificationModule.notifications.length - 1
            }
          }
        }
      }
      }

      // mini dashboard opens on right click
      Item {
        anchors.centerIn: parent
        width: box.implicitWidth - (Theme.panelPadding * 2)
        height: box.miniDashboard ? box.implicitHeight - (Theme.panelPadding * 2) : 0  // don't fight the animation
        opacity: box.miniDashboard
                 && !notificationModule.active
                 && !box.volumeActive
                 && !box.brightnessActive
                 && !box.batteryCharging
                 && !box.cliphistOpen ? 1 : 0

        Behavior on opacity {
          SequentialAnimation {
            PauseAnimation { duration: box.miniDashboard ? 1 : 0 }
            NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
          }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    box.miniDashboard = !box.miniDashboard
            }
        }

        visible: opacity > 0

        RowLayout {
          // profile picture
          Item {
            anchors.top: parent.top
            anchors.left: parent.left
            width: avatarSize
            height: avatarSize

            Image {
              id: avatarImg
              anchors.fill: parent
              source: "file://" + Config.displayPicture
              fillMode: Image.PreserveAspectCrop
              asynchronous: false
              visible: false
              sourceSize: Qt.size(avatarSize, avatarSize)
            }

            OpacityMask {
              anchors.fill: parent
              source: avatarImg
              maskSource: Rectangle {
                width: avatarSize
                height: avatarSize
                radius: avatarSize / 2
              }
            }
          }

          // username
          Process {
            id: whoamiProc
            command: ["sh", "-c", 'whoami']
            running: true
            stdout: StdioCollector {
              onStreamFinished: { whoamiText.text = this.text.trim(); whoamiProc.running = false }
            }
          }

          // hostname
          Process {
            id: hostnameProc
            command: ["sh", "-c", "cat /etc/hostname"]
            running: true
            stdout: StdioCollector {
              onStreamFinished: { hostnameText.text = "(" + this.text.trim() + ")"; hostnameProc.running = false }
            }
          }

          // uptime
          Process {
            id: uptimeProc
            command: ["sh", "-c", 'uptime -p']
            running: true
            stdout: StdioCollector {
              onStreamFinished: uptimeText.text = this.text
            }
          }

          // uptime refresh every 60 sec
          Timer {
            interval: 60000
            running: box.miniDashboard
            repeat: true
            triggeredOnStart: true
            onTriggered: {
              uptimeProc.running = false
              uptimeProc.running = true
            }
          }

          // username + uptime stacked
          ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
              Text {
                id: whoamiText
                color: Theme.fg
                Layout.leftMargin: 10
                font { family: Theme.fontFamily; pixelSize: 13; weight: 600 }
              }

              Text {
                id: hostnameText
                color: Theme.greyFg2
                Layout.topMargin: 2
                font { family: Theme.fontFamily; pixelSize: 9; weight: 300 }
              }
            }

            Text {
              id: uptimeText
              color: Theme.fg
              opacity: 0.6
              Layout.leftMargin: 10
              font { family: Theme.fontFamily; pixelSize: 8; weight: 400 }
            }
          }
        }

        // show battery in mini dashboard too
        Battery {
          fontSize: 14
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: 8
          anchors.rightMargin: 0
        }

        // system resource metrics
        Process {
          id: cpuMetricProc
          command: ["sh", "-c", "awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i} END {print idle, total}' /proc/stat; sleep 0.2; awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i} END {print idle, total}' /proc/stat"]
          running: false
          stdout: StdioCollector {
            onStreamFinished: {
              const values = this.text.trim().split(/\s+/).map(Number)
              if (values.length === 4) {
                const totalDelta = values[3] - values[1]
                const idleDelta = values[2] - values[0]
                if (totalDelta > 0)
                  dashboardCpu = Math.round(100 * (totalDelta - idleDelta) / totalDelta) + "%"
              }
            }
          }
        }

        Process {
          id: memoryMetricProc
          command: ["sh", "-c", "awk '/MemTotal:/ {total=$2} /MemAvailable:/ {available=$2} END {printf \"%.0f\", 100*(total-available)/total}' /proc/meminfo"]
          running: false
          stdout: StdioCollector {
            onStreamFinished: {
              const usage = this.text.trim()
              if (usage.length > 0) dashboardRam = usage + "%"
            }
          }
        }

        Process {
          id: diskMetricProc
          command: ["df", "-P", "/"]
          running: false
          stdout: StdioCollector {
            onStreamFinished: {
              const lines = this.text.trim().split("\n")
              if (lines.length > 1) {
                const fields = lines[lines.length - 1].trim().split(/\s+/)
                if (fields.length > 4) dashboardDisk = fields[4]
              }
            }
          }
        }

        Timer {
          interval: 5000
          running: box.miniDashboard
          repeat: true
          triggeredOnStart: true
          onTriggered: {
            cpuMetricProc.running = false
            memoryMetricProc.running = false
            diskMetricProc.running = false
            cpuMetricProc.running = true
            memoryMetricProc.running = true
            diskMetricProc.running = true
          }
        }

        RowLayout {
          anchors.top: parent.top
          anchors.topMargin: 58
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: 8

          DashboardMetric {
            Layout.fillWidth: true
            label: "CPU"
            value: dashboardCpu
            icon: ""
            accent: Theme.info
          }

          DashboardMetric {
            Layout.fillWidth: true
            label: "RAM"
            value: dashboardRam
            icon: ""
            accent: Theme.success
          }

          DashboardMetric {
            Layout.fillWidth: true
            label: "DISCO"
            value: dashboardDisk
            icon: "󰋊"
            accent: Theme.warning
          }
        }

        Process {
          id: codexUsageProc
          command: ["/usr/share/chillpill-shell/scripts/codex-usage.py"]
          running: false
          stdout: StdioCollector {
            onStreamFinished: {
              codexUsageLoading = false
              try {
                const data = JSON.parse(this.text.trim())
                codexLoggedIn = data.loggedIn === true
                codexUsageStale = data.stale === true
                codexConsumedPercent = Number(data.consumedPercent || 0)
                codexRemainingPercent = Number(data.remainingPercent || 0)
                codexResetsAt = data.resetsAt || ""
                codexUsageError = data.error || ""
              } catch (e) {
                codexUsageStale = true
                codexUsageError = "Datos de Codex no disponibles"
              }
            }
          }
        }

        CodexUsageCard {
          anchors.top: parent.top
          anchors.topMargin: 116
          anchors.left: parent.left
          anchors.right: parent.right
          loggedIn: codexLoggedIn
          loading: codexUsageLoading
          stale: codexUsageStale
          consumedPercent: codexConsumedPercent
          remainingPercent: codexRemainingPercent
          resetsAt: codexResetsAt
          errorText: codexUsageError
        }

        // internet protocol information
        IpStatus {
          anchors.left: parent.left
          anchors.leftMargin: 0
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 42
        }

        // bandwidth usage status
        Bandwidth {
          anchors.right: parent.right
          anchors.rightMargin: 0
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 42
        }

        // clock and weather bar
        Rectangle {
          color: Theme.oneBg2
          implicitWidth: 15
          implicitHeight: 30
          radius: Theme.controlRadius

          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right

          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.cardPadding
            anchors.rightMargin: Theme.cardPadding
            spacing: Theme.controlSpacing

            Item { Layout.fillWidth: true }

            Datetime { id: datetimeItem; dateFg: Theme.lightGrey; }

            Item { Layout.fillWidth: true }

            WeatherIndicator { id: weatherIndicatorItem }

            Item { Layout.fillWidth: true }
          }
        }
      }
      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }
    }

    // calendar popup box
    CalendarBox { id: calendarPopup }

    WeatherPopup { id: weatherPopupBox }

    // open calendar when click on date in mini dashboard
    Connections {
      target: datetimeItem
      function onToggleCalendar() {
        console.log("toggleCalendar launched, current opacity:", calendarPopup.opacity)
        calendarPopup.shown = !calendarPopup.shown
        weatherPopupBox.shown = false
      }
    }

    // open weather when click on weather in mini dashboard
    Connections {
      target: weatherIndicatorItem
      function onToggleWeather() {
        weatherPopupBox.shown = !weatherPopupBox.shown
        calendarPopup.shown = false
      }
    }

    Connections {
        target: mprisModule
        function onNowPlaying() {
          if (box.cliphistOpen || box.miniDashboard) return
          if (!box.controlCenter) mediaAutoOpened = true
          box.controlCenter = true
          mediaPopupHideTimer.restart()
        }
    }

    Timer {
        id: mediaPopupHideTimer
        interval: Config.mediaAutoOpenDuration
        repeat: false
        onTriggered: {
          if (mediaAutoOpened) {
            box.controlCenter = false
            mediaAutoOpened = false
          }
        }
    }

  }

  Mpris { id: mprisModule; visible: false }

  NotificationServer {
    id: notifServer
    keepOnReload: false
    onNotification: notif => {
      notif.tracked = true
      notificationModule.enqueue(notif)
    }
  }

  NotificationModule { id: notificationModule; visible: false }

  LockScreen { id: lockscreen }

  FullscreenOsd {
    id: fsNotif
    active: notificationModule.active && notifFullscreenMode
    visible: notifFullscreenMode
    cardWidth: 280
    cardHeight: 50

    property var displayNotif: null

    RowLayout {
      anchors.centerIn: parent
      spacing: 12

      Text {
        text: String.fromCodePoint(0xf0f3)
        color: Theme.fg
        font { family: Theme.nerdFontFamily; pixelSize: 14 }
        visible: cardIcon.status !== Image.Ready
      }

      Image {
        id: cardIcon
        width: 22; height: 22
        fillMode: Image.PreserveAspectCrop
        source: {
          if (fsNotif.displayNotif && fsNotif.displayNotif.image) return fsNotif.displayNotif.image
          if (fsNotif.displayNotif && fsNotif.displayNotif.appIcon) {
            return fsNotif.displayNotif.appIcon.startsWith("/")
              ? "file://" + fsNotif.displayNotif.appIcon
              : "image://icon/" + fsNotif.displayNotif.appIcon
          }
          return ""
        }
        sourceSize: Qt.size(22, 22)
        visible: status === Image.Ready
      }

      Column {
        spacing: 2

        Text {
          text: fsNotif.displayNotif ? fsNotif.displayNotif.summary : ""
          color: Theme.fg
          font { family: Theme.fontFamily; pixelSize: 10; weight: 600 }
          elide: Text.ElideRight
          Layout.maximumWidth: 200
        }

        Text {
          text: fsNotif.displayNotif ? fsNotif.displayNotif.body : ""
          color: Theme.greyFg2
          font { family: Theme.fontFamily; pixelSize: 9 }
          elide: Text.ElideRight
          visible: text !== ""
          Layout.maximumWidth: 200
        }
      }
    }
  }

  Connections {
    target: notificationModule
    function onActiveChanged() {
      if (notificationModule.active) notifFullscreenMode = fullscreenActive
    }
    function onCurrentChanged() {
      if (notificationModule.current) fsNotif.displayNotif = notificationModule.current
    }
  }

}
