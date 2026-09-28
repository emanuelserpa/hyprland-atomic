import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components

Item {
    id: root
    required property var theme

    implicitWidth: unifiedPill.implicitWidth
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function haystack(node) {
        return (
            String(node?.name ?? "") + " " +
            String(node?.description ?? "") + " " +
            String(node?.nickname ?? "")
        ).toLowerCase()
    }

    function isVirtualOutput(node) {
        const s = haystack(node)
        return s.includes("easy effects")
            || s.includes("easyeffects")
            || s.includes("auto_null")
            || s.includes("null sink")
            || s.includes("null-sink")
            || s.includes("combined")
            || s.includes("combine sink")
            || s.includes("virtual sink")
            || s.includes("virtual-sink")
            || s.includes("loopback")
    }

    function isVirtualInput(node) {
        const s = haystack(node)
        return s.includes("monitor")
            || s.includes("easy effects")
            || s.includes("easyeffects")
            || s.includes("loopback")
            || s.includes("virtual")
    }

    function availableOutputs() {
        const result = []
        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i]
            if (!node || !node.audio || !node.isSink || node.isStream) continue
            if (isVirtualOutput(node)) continue
            result.push(node)
        }
        return result
    }

    function availableInputs() {
        const result = []
        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i]
            if (!node || !node.audio || node.isSink || node.isStream) continue
            if (isVirtualInput(node)) continue
            result.push(node)
        }
        return result
    }

    function availableStreams() {
        const result = []
        const list = Pipewire.nodes ? Pipewire.nodes.values : []
        for (let i = 0; i < list.length; i++) {
            const node = list[i]
            if (!node || !node.audio || !node.isStream) continue
            const mediaClass = String(node.type || "")
            if (!node.isSink && !mediaClass.includes("Output") && !mediaClass.includes("Stream/Output/Audio"))
                continue
            const name = String(node.name || "")
            if (name.includes("quickshell") || name.includes("speaker_tuning"))
                continue
            result.push(node)
        }
        return result
    }

    readonly property var outputs: availableOutputs()
    readonly property var inputs: availableInputs()
    readonly property var streams: availableStreams()
    readonly property var trackedNodes: outputs.concat(inputs).concat(streams)

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    PwObjectTracker {
        objects: root.trackedNodes
    }

    Rectangle {
        id: unifiedPill
        height: root.theme ? root.theme.pillHeight : 25
        radius: root.theme ? root.theme.pillRadius : 6
        clip: true
        color: (sinkMouse.containsMouse || sourceMouse.containsMouse)
               ? (root.theme ? root.theme.pillBackgroundHover : Qt.rgba(69/255, 71/255, 90/255, 0.65))
               : (root.theme ? root.theme.pillBackground : Qt.rgba(49/255, 50/255, 68/255, 0.50))
        border.width: 1
        border.color: (sinkMouse.containsMouse || sourceMouse.containsMouse)
               ? (root.theme ? root.theme.pillBorderHover : Qt.rgba(88/255, 91/255, 112/255, 0.55))
               : (root.theme ? root.theme.pillBorder : Qt.rgba(69/255, 71/255, 90/255, 0.35))
        implicitWidth: contentRow.implicitWidth + 16

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            // Seção de Saída (Alto-falante / Fones)
            Row {
                id: sinkSection
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: {
                        if (!root.sink?.audio) return "󰕾"
                        if (root.sink.audio.muted) return "󰖁"
                        const v = Math.round(root.sink.audio.volume * 100)
                        return v < 34 ? "󰕿" : (v < 67 ? "󰖀" : "󰕾")
                    }
                    color: root.sink?.audio?.muted ? root.theme.red : root.theme.cyan
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: {
                        if (!root.sink?.audio) return "--%"
                        return Math.round(root.sink.audio.volume * 100) + "%"
                    }
                    color: root.sink?.audio?.muted ? root.theme.red : root.theme.offWhite
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Separador sutil
            Rectangle {
                id: sep
                width: 1
                height: 11
                color: Qt.rgba(88/255, 91/255, 112/255, 0.50)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Seção de Entrada (Microfone)
            Row {
                id: sourceSection
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: root.source?.audio?.muted ? "󰍭" : "󰍬"
                    color: root.source?.audio?.muted ? root.theme.grey : root.theme.pink
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: Boolean(root.source?.audio && !root.source.audio.muted)
                    text: root.source?.audio ? Math.round(root.source.audio.volume * 100) + "%" : ""
                    color: root.theme.offWhite
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // MouseArea para Saída (Esquerda)
        MouseArea {
            id: sinkMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width / 2
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            cursorShape: Qt.PointingHandCursor

            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    audioPopup.visible = !audioPopup.visible
                } else if (mouse.button === Qt.RightButton && root.sink?.audio) {
                    root.sink.audio.muted = !root.sink.audio.muted
                }
            }

            onWheel: function(wheel) {
                if (!root.sink?.audio) return
                const d = wheel.angleDelta.y > 0 ? 0.02 : -0.02
                root.sink.audio.volume =
                    Math.max(0, Math.min(1.5, root.sink.audio.volume + d))
            }
        }

        // MouseArea para Entrada / Microfone (Direita)
        MouseArea {
            id: sourceMouse
            anchors.left: sinkMouse.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            cursorShape: Qt.PointingHandCursor

            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    audioPopup.visible = !audioPopup.visible
                } else if (mouse.button === Qt.RightButton && root.source?.audio) {
                    root.source.audio.muted = !root.source.audio.muted
                }
            }

            onWheel: function(wheel) {
                if (!root.source?.audio) return
                const d = wheel.angleDelta.y > 0 ? 0.02 : -0.02
                root.source.audio.volume =
                    Math.max(0, Math.min(1.5, root.source.audio.volume + d))
            }
        }

        ToolTipBubble {
            theme: root.theme
            target: unifiedPill
            openLeft: true
            text: {
                if (sourceMouse.containsMouse) {
                    if (!root.source?.audio) return "Microfone indisponível"
                    const name = root.source.description || root.source.nickname || root.source.name || "Microfone"
                    return root.source.audio.muted ? name + " • Mutado (Botão direito para desmutar)" : name + " • " + Math.round(root.source.audio.volume * 100) + "%"
                } else if (sinkMouse.containsMouse) {
                    if (!root.sink?.audio) return "Saída indisponível"
                    const name = root.sink.description || root.sink.nickname || root.sink.name || "Saída de áudio"
                    return root.sink.audio.muted ? name + " • Mutado (Botão direito para desmutar)" : name + " • " + Math.round(root.sink.audio.volume * 100) + "%"
                }
                return ""
            }
            visible: (sinkMouse.containsMouse || sourceMouse.containsMouse) && text.length > 0
        }
    }

    AudioPopup {
        id: audioPopup
        theme: root.theme
        target: unifiedPill
        sink: root.sink
        source: root.source
        outputs: root.outputs
        inputs: root.inputs
        streams: root.streams

        onSettingsRequested: Quickshell.execDetached(["pwvucontrol"])
    }
}
