pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property string activeProfile: "balanced"
    property string activeLabel: "Balanceado"
    property var profiles: [
        { id: "performance", label: "Performance" },
        { id: "balanced", label: "Balanceado" },
        { id: "power-saver", label: "Economia" }
    ]
    property bool available: true
    property bool busy: false
    property string error: ""

    function refresh() {
        statusState.refresh()
    }

    function applyStatus(res) {
        if (!res || !res.ok)
            return
        root.available = Boolean(res.available)
        root.activeProfile = String(res.active ?? "balanced")
        if (res.profiles && res.profiles.length > 0)
            root.profiles = res.profiles
        const match = root.profiles.find(p => p.id === root.activeProfile)
        root.activeLabel = match ? match.label : root.activeProfile
    }

    function setProfile(profileId) {
        if (setProc.running)
            return
        root.busy = true
        root.error = ""
        setProc.command = ["python3", "-B", Quickshell.shellDir + "/scripts/energy-profile.py", "set", profileId]
        setProc.running = true
    }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    CommandJson {
        id: statusState
        command: ["python3", "-B", Quickshell.shellDir + "/scripts/energy-profile.py", "status"]
        interval: 0
        onDataChanged: root.applyStatus(data)
    }

    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false
                try {
                    const res = JSON.parse(this.text.trim())
                    if (res && !res.ok) {
                        root.error = String(res.error ?? "Erro ao alterar perfil")
                    }
                } catch (e) {}
                refreshTimer.restart()
            }
        }
    }
}
