pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string fontName: "Roboto"
    property string fontFamily: fontName
    property string font: fontName + " Medium"

    property string iconFont: "Material Icons Outlined"
    property string nerdFontFamily: Config.nerdFontFamily

    // Special
    property color white: "#edeff0"
    property color darkerBlack: "#060809"
    property color black: "#0c0e0f"
    property color lighterBlack: "#121415"
    property color oneBg: "#161819"
    property color oneBg2: "#1f2122"
    property color oneBg3: "#27292a"
    property color grey: "#343637"
    property color greyFg: "#3e4041"
    property color greyFg2: "#484a4b"
    property color lightGrey: "#505253"
    property color transparent: "#00000000"

    // ANSI-like palette
    property color color0: "#232526"
    property color color1: "#df5b61"
    property color color2: "#78b892"
    property color color3: "#de8f78"
    property color color4: "#6791c9"
    property color color5: "#bc83e3"
    property color color6: "#67afc1"
    property color color7: "#e4e6e7"
    property color color8: "#2c2e2f"
    property color color9: "#e8646a"
    property color color10: "#81c19b"
    property color color11: "#e79881"
    property color color12: "#709ad2"
    property color color13: "#c58cec"
    property color color14: "#70b8ca"
    property color color15: "#f2f4f5"

    // Core mappings used across the shell
    property color bg: black
    property color fg: white
    property color accent: color4

    // UI events
    property color leaveEvent: transparent
    property color enterEvent: "#ffffff10"
    property color pressEvent: "#ffffff15"
    property color releaseEvent: "#ffffff10"

    // Widget / surfaces
    property color widgetBg: "#1b1d1e"
    property color wibarBg: "#101213"
    property color titlebarBg: black
    property color titlebarFg: white

    // Semantic text, surface and state tokens. Components should use these
    // instead of introducing one-off colours that drift from the shell.
    property color surface: widgetBg
    property color surfaceRaised: oneBg2
    property color surfaceHover: oneBg3
    property color surfacePressed: grey
    property color surfaceBorder: oneBg3
    property color textPrimary: fg
    property color textSecondary: lightGrey
    property color textMuted: greyFg2
    property color textDisabled: greyFg
    property color textSubtle: "#ffffff10"
    property color danger: color1
    property color dangerBright: color9
    property color success: color2
    property color warning: color3
    property color info: color4

    // Lock screen palette, matching the AwesomeWM word-clock design.
    // Word-clock lockscreen surface and text tones from the reference.
    property color lockScreenBg: grey
    property color lockScreenDim: "#414344"
    property color lockScreenActive: "#b1b3b4"
    property color lockScreenHint: greyFg2
    readonly property bool materialIconsAvailable: Qt.fontFamilies().indexOf(iconFont) !== -1
    property string lockScreenSymbol: materialIconsAvailable ? "\ue897" : "\uf023"
    property string lockScreenFailSymbol: materialIconsAvailable ? "\ue641" : "\uf071"
    property string lockScreenIconFont: materialIconsAvailable ? iconFont : nerdFontFamily
    property int lockScreenGridSpacing: 6
    property int lockScreenGridCell: 36
    property int lockScreenGridFontSize: 24
    property int lockScreenArcSize: 100
    property int lockScreenIconSize: 40
    property int lockScreenContentSpacing: 60
    property int lockScreenTopPadding: 20

    // Other Awesome theme dimensions used by the Quickshell shell.
    property int wibarHeight: 40
    property int uselessGap: 2
    property int notificationSpacing: 4
    property int systrayIconSize: 20
    property int systrayIconSpacing: 10

    // Semantic accents used by data-driven modules.
    property color weatherSun: color3
    property color weatherRain: color4
    property color weatherStorm: color11
    property color weatherSnow: color15
    property color weatherFog: textSecondary

    // Reusable controls
    property int borderRadius: 12
    property int panelPadding: 12
    property int contentInset: 5
    property int cardPadding: 9
    property int controlSpacing: 8
    property int controlRadius: 10
    property color snapBg: color8

    function randomAccentColor() {
        const accents = [color9, color10, color11, color12, color13, color14];
        const i = Math.floor(Math.random() * accents.length);
        return accents[i];
    }
}
