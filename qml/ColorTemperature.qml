import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool enabled: false
    property int temperature: 4500
    readonly property int minimum: 2500
    readonly property int maximum: 6500

    function apply(): void {
        temperature = Math.max(minimum, Math.min(maximum, temperature))
        temperatureProc.command = enabled
            ? ["gammastep", "-O", temperature.toString()]
            : ["gammastep", "-x"]
        temperatureProc.running = false
        temperatureProc.running = true
    }

    function toggle(): void {
        enabled = !enabled
        apply()
    }

    function setTemperature(value): void {
        temperature = Math.round(value)
        if (enabled) apply()
    }

    function change(delta): void {
        enabled = true
        setTemperature(temperature + delta)
    }

    property Process temperatureProc: Process { running: false }
}
