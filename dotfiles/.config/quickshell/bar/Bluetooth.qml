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
    readonly property var bluetoothData: bluetoothState.data

    ActionFeedback { id: actionFeedback }

    CommandJson {
        id: bluetoothState
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/bluetooth-status.py"
        ]
        interval: popup.visible ? 2000 : 8000
    }

    function refresh() {
        bluetoothState.refresh()
    }

    function runAction(args, quiet, target) {
        if (actionProc.running)
            return

        actionFeedback.begin(target, quiet)

        actionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/bluetooth-action.py"
        ].concat(args)
        actionProc.running = true
    }

    function startDiscovery() {
        if (popup.visible
                && Boolean(bluetoothState.data?.available)
                && Boolean(bluetoothState.data?.powered)
                && !discoveryProc.running) {
            discoveryProc.running = true
        }
    }

    function stopDiscovery() {
        if (discoveryProc.running)
            discoveryProc.running = false

        if (!discoveryStopProc.running
                && Boolean(bluetoothState.data?.available)) {
            discoveryStopProc.running = true
        }
    }

    Process {
        id: actionProc

        stdout: StdioCollector {
            onStreamFinished: {
                let obj = null

                try {
                    obj = JSON.parse(this.text.trim())
                } catch (e) {
                    actionFeedback.fail("Resposta inválida do Bluetooth.")
                    return
                }

                if (!Boolean(obj.ok))
                    actionFeedback.fail(String(obj.error ?? "A operação Bluetooth falhou."))
                else
                    actionFeedback.succeed()
            }
        }

        onRunningChanged: {
            if (!running) {
                actionFeedback.finish()
                refreshDelay.restart()
            }
        }
    }

    // Keep discovery separate so its long-running command cannot block
    // connect/disconnect/power actions from the popup.
    Process {
        id: discoveryProc
        command: ["bluetoothctl", "scan", "on"]
    }

    Process {
        id: discoveryStopProc
        command: ["bluetoothctl", "scan", "off"]
    }

    Timer {
        id: refreshDelay
        interval: 650
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: discoveryRefresh
        interval: 1800
        repeat: true
        running: popup.visible && Boolean(bluetoothState.data?.powered)
        onTriggered: {
            root.startDiscovery()
            root.refresh()
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme

        text: {
            if (!bluetoothState.data?.powered)
                return "󰂲"

            const count = Number(bluetoothState.data?.connected_count ?? 0)
            return count > 0 ? (count > 1 ? "󰂱 " + count : "󰂱") : "󰂯"
        }

        textColor: !bluetoothState.data?.powered
                   ? root.theme.grey
                   : (Number(bluetoothState.data?.connected_count ?? 0) > 0
                      ? root.theme.green
                      : root.theme.cyan)

        tooltipText: (bluetoothState.data?.tooltip ?? "Bluetooth") + " • Botão direito: ligar/desligar"

        BluetoothPopup {
            id: popup
            theme: root.theme
            target: pill
            bluetoothData: bluetoothState.data
            busy: root.actionBusy
            busyTarget: root.actionBusyTarget
            errorText: root.actionError
            errorTarget: root.actionErrorTarget
            isScanning: discoveryProc.running

            onOpenedChanged: function(opened) {
                if (opened) {
                    root.refresh()
                    root.startDiscovery()
                } else {
                    root.stopDiscovery()
                }
            }

            onRefreshRequested: {
                root.refresh()
                root.startDiscovery()
            }

            onPowerToggleRequested: function(enabled) {
                if (!enabled)
                    root.stopDiscovery()

                root.runAction(
                    [enabled ? "power-on" : "power-off"],
                    false,
                    "__power__"
                )
            }

            onDeviceConnectRequested: function(mac) {
                root.runAction(["connect", mac], false, "device:" + mac)
            }

            onDeviceDisconnectRequested: function(mac) {
                root.runAction(["disconnect", mac], false, "device:" + mac)
            }

            onDevicePairRequested: function(mac) {
                root.runAction(["pair", mac], false, "device:" + mac)
            }

            onDeviceRemoveRequested: function(mac) {
                root.runAction(["remove", mac], false, "device:" + mac)
            }

            onSettingsRequested: Quickshell.execDetached(["blueberry"])
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                popup.visible = !popup.visible
            } else if (mouse.button === Qt.RightButton) {
                if (!Boolean(bluetoothState.data?.available))
                    return

                const enabled = !Boolean(bluetoothState.data?.powered)
                root.runAction(
                    [enabled ? "power-on" : "power-off"],
                    false,
                    "__power__"
                )
            }
        }
    }
}
