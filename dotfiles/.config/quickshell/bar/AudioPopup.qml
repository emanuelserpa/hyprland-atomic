import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property var sink: null
    property var source: null
    property var outputs: []
    property var inputs: []
    property var streams: []

    signal settingsRequested()

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    readonly property real streamsAreaHeight: streams.length > 0
        ? (22 + Math.min(140, streamList.implicitHeight))
        : 0

    implicitWidth: 360
    implicitHeight: Math.min(600, 460 + streamsAreaHeight)
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true


    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
        }
    }

    function nodeName(node, fallback) {
        if (!node) return fallback
        return node.description || node.nickname || node.name || fallback
    }

    function streamName(node) {
        if (!node) return "Aplicativo"
        const p = (node.ready && node.properties) ? node.properties : (node.properties || {})
        const app = p["application.name"] || node.description || p["node.name"] || node.name || p["media.name"]
        if (app && app.length > 0) return String(app)
        return "Aplicativo"
    }

    function streamDetail(node) {
        if (!node) return ""
        const p = node.properties || {}
        const media = String(p["media.name"] || "").trim()
        const app = streamName(node)
        const generic = ["audiostream", "audio stream", "playback", "output"]
        if (!media || media.toLowerCase() === app.toLowerCase()
                || generic.includes(media.toLowerCase())) return ""
        return media
    }

    function streamIcon(node) {
        const name = streamName(node).toLowerCase()
        if (name.includes("firefox")) return "󰈹"
        if (name.includes("chrome") || name.includes("chromium") || name.includes("brave")) return "󰊯"
        if (name.includes("spotify")) return "󰓇"
        if (name.includes("discord") || name.includes("vesktop") || name.includes("webcord")) return "󰙯"
        if (name.includes("telegram")) return "󰅣"
        if (name.includes("mpv") || name.includes("vlc") || name.includes("video") || name.includes("player")) return "󰕼"
        if (name.includes("steam") || name.includes("game")) return "󰊴"
        return "󰓃"
    }

    function setVolume(audio, mouseX, width) {
        if (!audio || width <= 0) return
        audio.volume = Math.max(0, Math.min(1.5, (mouseX / width) * 1.5))
    }


    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent

        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 9

            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Mixer de Áudio"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                Rectangle {
                    anchors.right: pipeBadge.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 24
                    radius: 6
                    color: settingsHover.hovered
                           ? Qt.rgba(137/255, 180/255, 250/255, 0.25)
                           : Qt.rgba(49/255, 50/255, 68/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: settingsHover.hovered ? root.theme.blue : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                    }

                    HoverHandler { id: settingsHover }
                    TapHandler { onTapped: root.settingsRequested() }
                }

                Rectangle {
                    id: pipeBadge
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: 58
                    radius: 9
                    color: Qt.rgba(69/255, 71/255, 90/255, 0.25)
                    border.width: 1
                    border.color: Qt.rgba(69/255, 71/255, 90/255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "PipeWire"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.borderSubtle
            }

            // OUTPUT ------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 88
                radius: 10
                color: root.theme.cardBackground
                border.width: 1
                border.color: root.theme.borderSubtle

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 9

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 9

                        Rectangle {
                            id: sinkMuteButton
                            width: 32
                            height: 32
                            radius: 8
                            color: sinkMuteHover.hovered
                                   ? root.theme.cardBackgroundActive
                                   : root.theme.cardBackgroundHover

                            Text {
                                anchors.centerIn: parent
                                text: root.sink?.audio?.muted ? "󰖁" : "󰕾"
                                color: root.sink?.audio?.muted ? root.theme.red : root.theme.cyan
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 15
                            }

                            HoverHandler { id: sinkMuteHover }
                            TapHandler {
                                onTapped: {
                                    if (root.sink?.audio)
                                        root.sink.audio.muted = !root.sink.audio.muted
                                }
                            }
                        }

                        Column {
                            width: parent.width - 41
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: root.sink?.audio?.muted ? "Saída · mutada" : "Saída"
                                color: root.sink?.audio?.muted ? root.theme.red : root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                            }

                            Text {
                                width: parent.width
                                text: root.nodeName(root.sink, "Nenhuma saída")
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Item {
                            width: parent.width - 50
                            height: 18

                            Rectangle {
                                id: sinkTrack
                                width: parent.width
                                height: 6
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 3
                                color: root.theme.cardBackgroundActive

                                Rectangle {
                                    id: sinkFill
                                    width: root.sink?.audio
                                           ? parent.width * Math.min(1, root.sink.audio.volume / 1.5)
                                           : 0
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.sink?.audio?.muted ? root.theme.grey : root.theme.cyan
                                }

                                Rectangle {
                                    width: 11
                                    height: 11
                                    radius: 5.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, sinkFill.width - width / 2))
                                    color: root.theme.foreground
                                    border.width: 2
                                    border.color: root.theme.cyan
                                    visible: sinkMouse.containsMouse || sinkMouse.pressed
                                }
                            }

                            MouseArea {
                                id: sinkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) {
                                    root.setVolume(root.sink?.audio, mouse.x, width)
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed)
                                        root.setVolume(root.sink?.audio, mouse.x, width)
                                }
                            }
                        }

                        Text {
                            width: 42
                            text: root.sink?.audio
                                  ? Math.round(root.sink.audio.volume * 100) + "%"
                                  : "--%"
                            color: root.theme.offWhite
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // APLICATIVOS (Per-App Streams) --------------------------------
            Column {
                visible: root.streams.length > 0
                width: parent.width
                spacing: 5

                Text {
                    text: "Aplicativos"
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Flickable {
                    id: streamFlick
                    width: parent.width
                    height: Math.min(130, streamList.implicitHeight)
                    contentWidth: width
                    contentHeight: streamList.implicitHeight
                    clip: true

                    WheelKinetic { target: streamFlick }

                    Column {
                        id: streamList
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.streams

                            delegate: Rectangle {
                                required property var modelData

                                width: streamList.width
                                height: root.streamDetail(modelData) ? 64 : 52
                                radius: 8
                                color: root.theme.cardBackgroundSubtle
                                border.width: 1
                                border.color: root.theme.borderSubtle

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    spacing: root.streamDetail(modelData) ? 2 : 4

                                    Row {
                                        width: parent.width
                                        height: 16
                                        spacing: 6

                                        Text {
                                            text: root.streamIcon(modelData)
                                            color: root.theme.cyan
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            width: parent.width - 95
                                            text: root.streamName(modelData)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Mute toggle
                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 4
                                            color: modelData.audio?.muted ? Qt.rgba(243/255, 139/255, 168/255, 0.25) : "transparent"
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.audio?.muted ? "󰖁" : "󰕾"
                                                color: modelData.audio?.muted ? root.theme.red : root.theme.grey
                                                font.family: root.theme.nerdFontFamily
                                                font.pixelSize: 10
                                            }

                                            TapHandler {
                                                onTapped: {
                                                    if (modelData.audio)
                                                        modelData.audio.muted = !modelData.audio.muted
                                                }
                                            }
                                        }

                                        Text {
                                            width: 42
                                            text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "--%"
                                            color: root.theme.offWhite
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignRight
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        visible: root.streamDetail(modelData).length > 0
                                        width: parent.width
                                        text: root.streamDetail(modelData)
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }

                                    // Mini volume slider
                                    Item {
                                        width: parent.width
                                        height: 18

                                        Rectangle {
                                            width: parent.width
                                            height: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 3
                                            color: Qt.rgba(88/255, 91/255, 112/255, 0.45)

                                            Rectangle {
                                                id: streamFill
                                                width: modelData.audio
                                                       ? parent.width * Math.min(1, modelData.audio.volume / 1.5)
                                                       : 0
                                                height: parent.height
                                                radius: parent.radius
                                                color: modelData.audio?.muted ? root.theme.grey : root.theme.cyan
                                            }

                                            Rectangle {
                                                width: 11
                                                height: 11
                                                radius: 5.5
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: Math.max(0, Math.min(parent.width - width, streamFill.width - width / 2))
                                                color: root.theme.foreground
                                                border.width: 2
                                                border.color: root.theme.cyan
                                                visible: streamMouse.containsMouse || streamMouse.pressed
                                            }
                                        }

                                        MouseArea {
                                            id: streamMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: function(mouse) {
                                                root.setVolume(modelData.audio, mouse.x, width)
                                            }
                                            onPositionChanged: function(mouse) {
                                                if (pressed)
                                                    root.setVolume(modelData.audio, mouse.x, width)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Outputs"
                color: root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            Flickable {
                id: outputFlick
                width: parent.width
                height: 76
                contentWidth: width
                contentHeight: outputList.implicitHeight
                clip: true

                WheelKinetic { target: outputFlick }

                Column {
                    id: outputList
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: root.outputs

                        delegate: Rectangle {
                            required property var modelData
                            width: outputList.width
                            height: 30
                            radius: 6
                            color: modelData === root.sink
                                   ? Qt.rgba(108/255,99/255,187/255,0.30)
                                   : outputHover.hovered
                                     ? Qt.rgba(69/255,71/255,90/255,0.52)
                                     : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                Text {
                                    text: modelData === root.sink ? "󰓃" : "󰓄"
                                    color: modelData === root.sink ? root.theme.green : root.theme.cyan
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 25
                                    text: root.nodeName(modelData, "Output")
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler { id: outputHover }
                            TapHandler {
                                onTapped: Pipewire.preferredDefaultAudioSink = modelData
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.borderSubtle
            }

            // INPUT -------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 88
                radius: 10
                color: root.theme.cardBackground
                border.width: 1
                border.color: root.theme.borderSubtle

                Column {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 9

                        Rectangle {
                            id: micMuteButton
                            width: 32
                            height: 32
                            radius: 8
                            color: micMuteHover.hovered
                                   ? root.theme.cardBackgroundActive
                                   : root.theme.cardBackgroundHover

                            Text {
                                anchors.centerIn: parent
                                text: root.source?.audio?.muted ? "󰍭" : "󰍬"
                                color: root.source?.audio?.muted ? root.theme.red : root.theme.pink
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 15
                            }

                            HoverHandler { id: micMuteHover }
                            TapHandler {
                                onTapped: {
                                    if (root.source?.audio)
                                        root.source.audio.muted = !root.source.audio.muted
                                }
                            }
                        }

                        Column {
                            width: parent.width - 41
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: root.source?.audio?.muted ? "Microfone · mutado" : "Microfone"
                                color: root.source?.audio?.muted ? root.theme.red : root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                            }

                            Text {
                                width: parent.width
                                text: root.nodeName(root.source, "Nenhuma entrada")
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Item {
                            width: parent.width - 50
                            height: 18

                            Rectangle {
                                width: parent.width
                                height: 6
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 3
                                color: root.theme.cardBackgroundActive

                                Rectangle {
                                    id: sourceFill
                                    width: root.source?.audio
                                           ? parent.width * Math.min(1, root.source.audio.volume / 1.5)
                                           : 0
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.source?.audio?.muted ? root.theme.grey : root.theme.pink
                                }

                                Rectangle {
                                    width: 11
                                    height: 11
                                    radius: 5.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, sourceFill.width - width / 2))
                                    color: root.theme.foreground
                                    border.width: 2
                                    border.color: root.theme.pink
                                    visible: sourceMouse.containsMouse || sourceMouse.pressed
                                }
                            }

                            MouseArea {
                                id: sourceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) {
                                    root.setVolume(root.source?.audio, mouse.x, width)
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed)
                                        root.setVolume(root.source?.audio, mouse.x, width)
                                }
                            }
                        }

                        Text {
                            width: 42
                            text: root.source?.audio
                                  ? Math.round(root.source.audio.volume * 100) + "%"
                                  : "--%"
                            color: root.theme.offWhite
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            Text {
                text: "Inputs"
                color: root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            Flickable {
                id: inputFlick
                width: parent.width
                height: 76
                contentWidth: width
                contentHeight: inputList.implicitHeight
                clip: true

                WheelKinetic { target: inputFlick }

                Column {
                    id: inputList
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: root.inputs

                        delegate: Rectangle {
                            required property var modelData
                            width: inputList.width
                            height: 30
                            radius: 6
                            color: modelData === root.source
                                   ? Qt.rgba(108/255,99/255,187/255,0.30)
                                   : inputHover.hovered
                                     ? Qt.rgba(69/255,71/255,90/255,0.52)
                                     : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 7

                                Text {
                                    text: modelData === root.source ? "󰍬" : "󰍮"
                                    color: modelData === root.source ? root.theme.green : root.theme.pink
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 25
                                    text: root.nodeName(modelData, "Entrada")
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler { id: inputHover }
                            TapHandler {
                                onTapped: Pipewire.preferredDefaultAudioSource = modelData
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
