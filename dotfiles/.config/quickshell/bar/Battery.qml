import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.components
import qs.services

Pill {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property real pct: bat?.ready ? bat.percentage * 100 : 0
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || bat?.state === UPowerDeviceState.FullyCharged
    readonly property real watts: bat?.ready ? Math.abs(bat.changeRate) : 0
    readonly property real secondsRemaining:
        !bat?.ready ? 0 : (charging ? bat.timeToFull : bat.timeToEmpty)

    property string profileError: ""
    property bool profileBusy: false
    property string chargeLimitError: ""
    property bool chargeLimitBusy: false

    onPluggedChanged: {
        if (plugged)
            NotificationState.dismissBatteryAlerts()
    }

    CommandJson {
        id: profileState
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/energy-profile.py",
            "status"
        ]
        interval: popup.visible ? 8000 : 0
        autoStart: false
    }

    CommandJson {
        id: chargeLimitState
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/battery-charge-limit.py",
            "status"
        ]
        interval: popup.visible ? 8000 : 0
        autoStart: false
    }

    Process {
        id: profileAction

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.profileError = Boolean(obj.ok)
                                        ? ""
                                        : String(obj.error ?? "Falha ao alterar o perfil.")
                } catch (e) {
                    root.profileError = "Resposta inválida do perfil de energia."
                }
            }
        }

        onRunningChanged: {
            root.profileBusy = running
            if (!running)
                profileRefresh.restart()
        }
    }

    Timer {
        id: profileRefresh
        interval: 350
        repeat: false
        onTriggered: profileState.refresh()
    }

    Process {
        id: chargeLimitAction

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.chargeLimitError = Boolean(obj.ok)
                                                ? ""
                                                : String(obj.error ?? "Falha ao alterar o limite.")
                } catch (e) {
                    root.chargeLimitError = "Resposta inválida do limite de carga."
                }
            }
        }

        onRunningChanged: {
            root.chargeLimitBusy = running
            if (!running)
                chargeLimitRefresh.restart()
        }
    }

    Timer {
        id: chargeLimitRefresh
        interval: 350
        repeat: false
        onTriggered: chargeLimitState.refresh()
    }

    function setChargeLimit(mode) {
        if (chargeLimitAction.running)
            return

        root.chargeLimitError = ""
        chargeLimitAction.command = [
            "python3",
            Quickshell.shellDir + "/scripts/battery-charge-limit.py",
            "set",
            mode
        ]
        chargeLimitAction.running = true
    }

    function setProfile(profile) {
        if (profileAction.running)
            return

        root.profileError = ""
        profileAction.command = [
            "python3",
            Quickshell.shellDir + "/scripts/energy-profile.py",
            "set",
            profile
        ]
        profileAction.running = true
    }

    function iconFor(p) {
        if (p < 15) return "󰁺"
        if (p < 35) return "󰁼"
        if (p < 60) return "󰁾"
        if (p < 85) return "󰂀"
        return "󰁹"
    }

    text: charging
          ? "󰂄 " + Math.round(pct) + "%"
          : plugged
            ? "󰚥 " + Math.round(pct) + "%"
            : iconFor(pct) + " " + Math.round(pct) + "%"

    highlighted: popup.visible || (Boolean(bat?.ready) && !plugged && pct <= 15)

    textColor: {
        if (!root.theme) return "#bac2de"
        if (!bat?.ready) return root.theme.offWhite
        if (charging) return root.theme.green
        if (!plugged && pct <= 15) return root.theme.red
        if (!plugged && pct <= 30) return root.theme.yellow
        return root.theme.offWhite
    }

    function formatRemaining(sec) {
        if (!sec || sec <= 0) return ""
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }

    tooltipText: {
        const p = Math.round(pct)
        const rem = formatRemaining(secondsRemaining)
        if (charging) {
            return rem ? "Carregando: " + p + "% (" + rem + " até 100%)" : "Carregando: " + p + "%"
        }
        if (plugged) {
            return "Carga completa: " + p + "%"
        }
        return rem ? "Bateria: " + p + "% (" + rem + " restantes)" : "Bateria: " + p + "%"
    }

    BatteryPopup {
        id: popup
        theme: root.theme
        target: root
        percentage: root.pct
        charging: root.charging
        plugged: root.plugged
        watts: root.watts
        secondsRemaining: root.secondsRemaining
        profileData: profileState.data
        profileBusy: root.profileBusy
        profileError: root.profileError
        chargeLimitData: chargeLimitState.data
        chargeLimitBusy: root.chargeLimitBusy
        chargeLimitError: root.chargeLimitError
        stateText: root.charging
                   ? "Carregando"
                   : (root.plugged ? "Carga completa" : "Na bateria")

        onProfileRequested: function(profile) {
            root.setProfile(profile)
        }

        onChargeLimitRequested: function(mode) {
            root.setChargeLimit(mode)
        }
    }

    mouseArea.onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible
            if (popup.visible) {
                profileState.refresh()
                chargeLimitState.refresh()
            }
        }
    }
}
