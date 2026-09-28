import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root

    required property var theme

    implicitWidth: root.visible ? pill.implicitWidth : 0
    implicitHeight: root.visible ? (root.theme ? root.theme.pillHeight : 25) : 0
    visible: Boolean(phoneState.data?.visible ?? false)

    property alias actionError: actionFeedback.errorText
    property alias actionErrorTarget: actionFeedback.errorTarget
    property alias actionBusyTarget: actionFeedback.busyTarget
    property alias actionBusy: actionFeedback.busy
    readonly property var phoneData: phoneState.data

    ActionFeedback { id: actionFeedback }

    CommandJson {
        id: phoneState
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/kdeconnect-status.py"
        ]
        interval: popup.visible ? 5000 : 15000
    }

    function refresh() {
        phoneState.refresh()
    }

    function firstReachableId() {
        const devs = phoneState.data?.devices ?? []
        for (let i = 0; i < devs.length; i++) {
            if (Boolean(devs[i].reachable))
                return String(devs[i].id)
        }
        return ""
    }

    function runAction(args, quiet, target) {
        if (actionProc.running)
            return
        actionFeedback.begin(target, quiet)
        actionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/kdeconnect-action.py"
        ].concat(args)
        actionProc.running = true
    }

    Process {
        id: actionProc

        stdout: StdioCollector {
            onStreamFinished: {
                let obj = null
                try {
                    obj = JSON.parse(this.text.trim())
                } catch (e) {
                    actionFeedback.fail("Resposta inválida do KDE Connect.")
                    return
                }
                if (!Boolean(obj.ok)) {
                    actionFeedback.fail(String(obj.error ?? "A operação falhou."))
                } else {
                    actionFeedback.succeed()
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                actionFeedback.finish()
                refreshDelay.restart()
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 800
        repeat: false
        onTriggered: root.refresh()
    }

    function openSettings() {
        Quickshell.execDetached([
            "sh", "-c",
            "kdeconnect-app 2>/dev/null || kdeconnect-settings 2>/dev/null || plasmawindowed org.kde.kdeconnect 2>/dev/null || true"
        ])
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme
        text: String(phoneState.data?.text ?? "󰏲")
        textColor: Number(phoneState.data?.reachable_count ?? 0) > 0 ? root.theme.green : root.theme.grey
        tooltipText: String(phoneState.data?.tooltip ?? "Telefone") + " • Botão direito: ping"

        PhonePopup {
            id: popup
            theme: root.theme
            target: pill
            phoneData: phoneState.data
            busy: root.actionBusy
            busyTarget: root.actionBusyTarget
            errorText: root.actionError
            errorTarget: root.actionErrorTarget

            onRefreshRequested: root.refresh()
            onPingRequested: function(id) {
                root.runAction(["ping", id], false, "device:" + id)
            }
            onRingRequested: function(id) {
                root.runAction(["ring", id], false, "device:" + id)
            }
            onPairRequested: function(id) {
                root.runAction(["pair", id], false, "device:" + id)
            }
            onUnpairRequested: function(id) {
                root.runAction(["unpair", id], false, "device:" + id)
            }
            onShareTextRequested: function(id, message) {
                root.runAction(["share-text", id, message], false, "device:" + id)
            }
            onShareFileRequested: function(id, path) {
                root.runAction(["share", id, path], false, "device:" + id)
            }
            onSettingsRequested: root.openSettings()
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                popup.visible = !popup.visible
                if (popup.visible)
                    root.refresh()
            } else if (mouse.button === Qt.RightButton) {
                const id = root.firstReachableId()
                if (id.length > 0)
                    root.runAction(["ping", id], false, "device:" + id)
            }
        }
    }
}
