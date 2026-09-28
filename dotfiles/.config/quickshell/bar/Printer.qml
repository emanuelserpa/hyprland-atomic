import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root

    required property var theme

    readonly property bool detected: Boolean(printerState.data?.visible)
    readonly property int jobCount: Number(printerState.data?.job_count ?? 0)
    readonly property string status: String(printerState.data?.status ?? "ready")

    implicitWidth: detected ? pill.implicitWidth : 0
    implicitHeight: root.theme ? root.theme.pillHeight : 25
    visible: detected

    property alias actionError: actionFeedback.errorText
    property alias actionBusy: actionFeedback.busy

    ActionFeedback {
        id: actionFeedback
        clearAfter: 0
    }

    CommandJson {
        id: printerState
        command: ["python3", Quickshell.shellDir + "/scripts/printer-status.py"]
        interval: root.jobCount > 0 || queueWindow.visible ? 2000
                  : (root.detected ? 5000 : 10000)
    }

    function refresh() {
        printerState.refresh()
    }

    Process {
        id: actionProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    if (Boolean(obj.ok))
                        actionFeedback.succeed()
                    else
                        actionFeedback.fail(String(obj.error ?? "Falha na operação."))
                } catch (e) {
                    actionFeedback.fail("Resposta inválida ao operar a impressora.")
                }
            }
        }

        onRunningChanged: {
            if (running)
                actionFeedback.busy = true
            else {
                actionFeedback.finish()
                refreshDelay.restart()
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 450
        repeat: false
        onTriggered: root.refresh()
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme

        text: root.jobCount > 0 ? "󰐪 " + root.jobCount : "󰐪"

        textColor: root.status === "error"
                   ? root.theme.red
                   : (root.status === "printing"
                      ? root.theme.orange
                      : root.theme.blue)

        highlighted: root.jobCount > 0 || root.status === "error"
        tooltipText: String(printerState.data?.tooltip ?? "Impressora") + " • Botão direito: atualizar"

        PrinterPopup {
            id: popup
            theme: root.theme
            target: pill
            printerData: printerState.data
            errorText: root.actionError
            busy: root.actionBusy

            onRefreshRequested: root.refresh()

            onCancelRequested: function(jobId) { root.cancelJob(jobId) }
            onQueueRequested: {
                popup.visible = false
                queueWindow.visible = true
                root.refresh()
            }

            onSettingsRequested: Quickshell.execDetached([
                "sh", "-c",
                "command -v system-config-printer >/dev/null 2>&1 "
                + "&& exec system-config-printer "
                + "|| exec xdg-open http://localhost:631/printers"
            ])
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                popup.visible = !popup.visible
                if (popup.visible)
                    root.refresh()
            } else if (mouse.button === Qt.RightButton) {
                root.refresh()
            }
        }
    }

    function cancelJob(jobId) {
        if (actionProc.running || jobId.length === 0)
            return

        actionFeedback.begin("")
        actionProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/printer-action.py",
            "cancel",
            jobId
        ]
        actionProc.running = true
    }

    PrinterQueueWindow {
        id: queueWindow
        theme: root.theme
        printerData: printerState.data
        errorText: root.actionError
        busy: root.actionBusy
        onRefreshRequested: root.refresh()
        onCancelRequested: function(jobId) { root.cancelJob(jobId) }
    }
}
