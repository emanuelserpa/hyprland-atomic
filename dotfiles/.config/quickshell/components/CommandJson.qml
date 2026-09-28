import QtQuick
import Quickshell.Io

Item {
    id: root
    property list<string> command: []
    property int interval: 600000
    property bool autoStart: true
    property string text: ""
    property string tooltip: ""
    property string cssClass: ""
    property var data: ({})
    property int generation: 0
    width: 0
    height: 0

    function refresh() {
        if (!proc.running)
            proc.running = true
    }

    Component.onCompleted: {
        if (root.autoStart)
            refresh()
    }

    Timer {
        interval: root.interval
        repeat: true
        running: root.autoStart && root.interval > 0
        onTriggered: root.refresh()
    }

    Process {
        id: proc
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.data = obj
                    root.generation++
                    root.text = obj.text ?? ""
                    root.tooltip = obj.tooltip ?? ""
                    root.cssClass = Array.isArray(obj.class) ? obj.class.join(" ") : (obj.class ?? "")
                } catch (e) {
                    root.data = ({})
                    root.text = ""
                    root.tooltip = "Erro ao interpretar saída: " + e
                }
            }
        }
    }
}
