import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root

    required property var theme

    implicitWidth: pill.implicitWidth
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    property alias actionError: actionFeedback.errorText
    property alias actionErrorTarget: actionFeedback.errorTarget
    property alias actionBusyTarget: actionFeedback.busyTarget
    property alias actionBusy: actionFeedback.busy
    property string pendingInput: ""

    ActionFeedback { id: actionFeedback }

    readonly property var networkData: networkState.data

    readonly property var activeVpns: {
        const list = networkState.data?.vpns ?? []
        return list.filter(function(vpn) { return Boolean(vpn.active) })
    }

    readonly property bool vpnActive: activeVpns.length > 0

    readonly property string activeVpnNames: activeVpns
        .map(function(vpn) { return String(vpn.name ?? "") })
        .filter(function(name) { return name.length > 0 })
        .join(", ")

    readonly property var popupData: {
        const state = networkState.data ?? ({})
        const scan = networkScan.data ?? ({})
        return {
            text: state.text ?? "",
            tooltip: state.tooltip ?? "",
            wifi_enabled: Boolean(state.wifi_enabled),
            active_ssid: state.active_ssid ?? "",
            active_connection: state.active_connection ?? "",
            active_device: state.active_device ?? "",
            active_type: state.active_type ?? "none",
            active_ip: state.active_ip ?? "",
            active_signal: Number(state.active_signal ?? 0),
            active_freq: state.active_freq ?? "",
            rx_bytes: Number(state.rx_bytes ?? 0),
            tx_bytes: Number(state.tx_bytes ?? 0),
            portal: Boolean(state.portal),
            networks: scan.networks ?? [],
            vpns: state.vpns ?? [],
            status: state.status ?? "ok"
        }
    }

    // Dynamic interval: 2s when popup is open for live telemetry, 8s when closed.
    CommandJson {
        id: networkState
        command: ["python3", Quickshell.shellDir + "/scripts/network-status.py"]
        interval: popup.visible ? 2000 : 8000
    }

    // Expensive Wi‑Fi scan: only called explicitly.
    CommandJson {
        id: networkScan
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/network-status.py",
            "--scan"
        ]
        interval: 0
        autoStart: false
    }

    function refreshState() {
        networkState.refresh()
    }

    function refreshScan() {
        networkScan.refresh()
    }

    function refreshPopup() {
        refreshState()
        refreshScan()
    }

    function runAction(args, quiet, target, input) {
        if (actionProc.running)
            return

        root.pendingInput = input === undefined ? "" : String(input)
        actionFeedback.begin(target, quiet)

        actionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/network-action.py"
        ].concat(args)
        actionProc.running = true
    }

    Process {
        id: actionProc
        stdinEnabled: true

        onStarted: {
            if (root.pendingInput.length > 0) {
                actionProc.write(root.pendingInput + "\n")
                root.pendingInput = ""
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                let obj = null
                try {
                    obj = JSON.parse(this.text.trim())
                } catch (e) {
                    actionFeedback.fail("A operação de rede retornou uma resposta inválida.")
                    return
                }

                if (obj && obj.action === "wifi-qr" && Boolean(obj.ok)) {
                    popup.qrData = obj
                    popup.showQr = true
                }

                if (obj && obj.action === "connect-password" && Boolean(obj.ok))
                    passwordDialog.visible = false

                if (!Boolean(obj.ok))
                    actionFeedback.fail(String(obj.error ?? "A operação de rede falhou."))
                else
                    actionFeedback.succeed()
            }
        }

        onRunningChanged: {
            if (!running) {
                root.pendingInput = ""
                actionFeedback.finish()
                refreshDelay.restart()
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 700
        repeat: false
        onTriggered: {
            root.refreshState()
            if (popup.visible)
                root.refreshScan()
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme

        text: {
            let icon = "󰤮"

            if (networkState.data?.active_type === "ethernet") {
                icon = "󰈀"
            } else if (networkState.data?.active_ssid) {
                const sig = Number(networkState.data?.active_signal ?? 0)
                if (sig >= 80) icon = "󰤨"
                else if (sig >= 60) icon = "󰤥"
                else if (sig >= 40) icon = "󰤢"
                else if (sig >= 20) icon = "󰤟"
                else icon = "󰤯"
            } else if (networkState.data?.wifi_enabled) {
                icon = "󰤯"
            } else {
                icon = "󰤭"
            }

            return root.vpnActive ? icon + " 󰌾" : icon
        }

        tooltipText: {
            let tip = networkState.tooltip || "Rede"
            if (root.vpnActive) {
                const vpnDesc = root.activeVpnNames.length > 0
                    ? "VPN: " + root.activeVpnNames
                    : "VPN conectada"
                tip += "\n" + vpnDesc
            }
            tip += " • Botão direito: atualizar"
            return tip
        }

        textColor: {
            if (root.vpnActive)
                return root.theme.green
            if (networkState.data?.active_type === "ethernet" || networkState.data?.active_ssid)
                return root.theme.cyan
            if (networkState.data?.wifi_enabled)
                return root.theme.grey
            return root.theme.red
        }

        NetworkPopup {
            id: popup
            theme: root.theme
            target: pill
            networkData: root.popupData
            errorText: root.actionError
            errorTarget: root.actionErrorTarget
            busy: root.actionBusy
            busyTarget: root.actionBusyTarget

            onRefreshRequested: root.refreshPopup()

            onWifiToggleRequested: function(enabled) {
                root.runAction([enabled ? "wifi-on" : "wifi-off"], false, "__wifi__")
            }

            onDisconnectRequested: function(device) {
                root.runAction(["disconnect", device], false, "wifi:" + String(root.popupData.active_ssid ?? ""))
            }

            onConnectRequested: function(ssid, uuid, saved, secure) {
                if (saved && uuid.length > 0) {
                    root.runAction(["connect-saved", uuid], false, "wifi:" + ssid)
                } else if (!secure) {
                    root.runAction(["connect-open", ssid], false, "wifi:" + ssid)
                } else {
                    popup.visible = false
                    Qt.callLater(function() { passwordDialog.openFor(ssid) })
                }
            }

            onPasswordPromptRequested: function(ssid) {
                popup.visible = false
                Qt.callLater(function() { passwordDialog.openFor(ssid) })
            }

            onQrRequested: function() {
                root.runAction(["wifi-qr"], false, "__qr__")
            }

            onCopyRequested: function(text) {
                root.runAction(["copy"], true, "", text)
            }

            onOpenPortalRequested: {
                root.runAction(["open-portal"], true, "")
            }

            onVpnToggleRequested: function(uuid, active) {
                root.runAction([active ? "vpn-down" : "vpn-up", uuid], false, "vpn:" + uuid)
            }

            onSettingsRequested: root.runAction(["editor"], true, "")
        }

        NetworkPasswordDialog {
            id: passwordDialog
            theme: root.theme
            target: pill
            errorText: root.actionErrorTarget === "wifi:" + ssid ? root.actionError : ""
            busy: root.actionBusy && root.actionBusyTarget === "wifi:" + ssid
            onConnectRequested: function(ssid, password) {
                root.runAction(["connect-password", ssid], false, "wifi:" + ssid, password)
            }
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (passwordDialog.visible) {
                    passwordDialog.visible = false
                    return
                }
                const opening = !popup.visible
                popup.visible = opening

                if (opening) {
                    // This is the only automatic path that triggers a Wi-Fi scan.
                    root.refreshPopup()
                }
            } else if (mouse.button === Qt.RightButton) {
                // Explicit user refresh may scan even with popup closed.
                root.refreshPopup()
            }
        }
    }
}
