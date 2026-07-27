import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string activeProfile: "balanced"
    property list<string> availableProfiles: []
    property bool daemonAvailable: false
    property string errorMessage: ""

    function supported(profile): bool {
        return availableProfiles.indexOf(profile) !== -1
    }

    function refresh(): void {
        listProfiles.running = false
        listProfiles.running = true
        getProfile.running = false
        getProfile.running = true
    }

    function setProfile(profile): void {
        if (!daemonAvailable || !supported(profile)) return
        activeProfile = profile
        setProfileProc.command = ["powerprofilesctl", "set", profile]
        setProfileProc.running = false
        setProfileProc.running = true
    }

    property Process getProfile: Process {
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const profile = text.trim()
                if (profile.length > 0) root.activeProfile = profile
            }
        }
        onExited: (exitCode) => {
            root.daemonAvailable = exitCode === 0
            root.errorMessage = exitCode === 0 ? "" : "power-profiles-daemon no está disponible"
        }
    }

    property Process listProfiles: Process {
        command: ["powerprofilesctl", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const found = []
                const known = ["power-saver", "balanced", "performance"]
                for (const profile of known) {
                    if (text.indexOf(profile + ":") !== -1) found.push(profile)
                }
                root.availableProfiles = found
            }
        }
    }

    property Process setProfileProc: Process {
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0) root.errorMessage = "No se pudo cambiar el perfil"
            root.refresh()
        }
    }
}
