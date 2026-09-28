import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root

    required property var theme
    implicitWidth: pill.implicitWidth
    implicitHeight: root.theme.pillHeight
    // Só ocupa espaço na barra durante gravação ou com o popup aberto.
    visible: root.recording || popup.visible

    property string actionError: ""
    property string lastSaved: ""
    readonly property bool recording: Boolean(recordingState.data?.active)
    readonly property bool hasAudio: Boolean(recordingState.data?.audio)
    readonly property int elapsed: Number(recordingState.data?.elapsed ?? 0)
    readonly property bool busy: actionProc.running
    property string pendingMode: ""
    property bool pendingAudio: false
    property bool audioEnabled: false

    function timeLabel(seconds) {
        const minutes = Math.floor(seconds / 60)
        const remaining = seconds % 60
        return minutes + ":" + String(remaining).padStart(2, "0")
    }

    function action(command) {
        if (actionProc.running) return
        actionError = ""
        lastSaved = ""
        actionProc.command = ["python3", Quickshell.shellDir + "/scripts/screen-recording.py"].concat(command)
        actionProc.running = true
    }

    CommandJson {
        id: recordingState
        command: ["python3", Quickshell.shellDir + "/scripts/screen-recording.py", "status"]
        interval: root.recording ? 1000 : 5000
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
            onStreamFinished: {
                let result = null
                try { result = JSON.parse(this.text.trim()) } catch (error) {}
                if (!result || !result.ok) {
                    root.actionError = String(result?.error ?? "Não foi possível controlar a gravação.")
                    if (root.actionError !== "Seleção cancelada.") popup.visible = true
                } else if (!result.active && result.path) {
                    root.lastSaved = String(result.path)
                    popup.visible = true
                }
                recordingState.refresh()
            }
        }
        onRunningChanged: {
            if (!running) recordingState.refresh()
        }
    }

    Timer {
        id: selectionDelay
        interval: 180
        repeat: false
        onTriggered: {
            const args = ["start", root.pendingMode]
            if (root.pendingAudio) args.push("--audio")
            root.action(args)
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme
        text: root.recording ? ("● " + root.timeLabel(root.elapsed) + (root.hasAudio ? " 󰕾" : "")) : "󰕧"
        textColor: root.recording ? root.theme.red : root.theme.offWhite
        highlighted: popup.visible || root.recording
        tooltipText: root.recording
            ? ("Gravando tela" + (root.hasAudio ? " com áudio" : "") + " • Clique para parar")
            : "Gravar tela"
        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) popup.visible = !popup.visible
        }
    }

    ScreenRecordingPopup {
        id: popup
        theme: root.theme
        target: pill
        recording: root.recording
        hasAudio: root.hasAudio
        withAudio: root.audioEnabled
        busy: root.busy
        elapsedText: root.timeLabel(root.elapsed)
        errorText: root.actionError
        savedPath: root.lastSaved
        onWithAudioChanged: {
            root.audioEnabled = withAudio
        }
        onStartRequested: function(mode, audio) {
            popup.visible = false
            root.pendingMode = mode
            root.pendingAudio = audio
            root.audioEnabled = audio
            selectionDelay.restart()
        }
        onStopRequested: root.action(["stop"])
    }

}
