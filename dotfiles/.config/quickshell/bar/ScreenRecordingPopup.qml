import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property bool recording: false
    property bool hasAudio: false
    property bool withAudio: false
    property bool busy: false
    property string elapsedText: "0:00"
    property string errorText: ""
    property string savedPath: ""

    signal startRequested(string mode, bool audio)
    signal stopRequested()

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6
    implicitWidth: 302
    implicitHeight: root.recording ? 265 : 280
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    onVisibleChanged: {

        if (visible) card.forceActiveFocus()
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 7

            Text {
                text: root.recording ? ("Gravando tela" + (root.hasAudio ? "  󰕾  " : "  ") + root.elapsedText) : "Gravar tela"
                color: root.recording ? root.theme.red : root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                text: root.recording
                    ? (root.hasAudio ? "Vídeo e áudio serão salvos em Vídeos." : "O vídeo será salvo em Vídeos.")
                    : "Escolha o que deseja gravar"
                color: root.theme.offWhite
                font.family: root.theme.fontFamily
                font.pixelSize: 10
            }

            Rectangle {
                width: 274
                height: 38
                radius: root.theme.radiusMd
                visible: !root.recording
                color: audioHover.hovered && !root.busy
                       ? root.theme.surfaceHover : root.theme.cardBackground
                opacity: root.busy ? 0.45 : 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        width: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.withAudio ? "󰕾" : "󰖁"
                        color: root.withAudio ? root.theme.green : root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 15
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 174
                        spacing: 1

                        Text {
                            text: "Gravar áudio"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.withAudio ? "Som ativado (microfone/sistema)" : "Som desabilitado"
                            color: root.withAudio ? root.theme.green : root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        height: 20
                        radius: 10
                        color: root.withAudio ? root.theme.green : root.theme.surface

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.withAudio ? 21 : 3
                            color: root.withAudio ? root.theme.backgroundOpaque : root.theme.offWhite

                            Behavior on x {
                                enabled: root.theme.qmlAnimationsEnabled
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }

                HoverHandler { id: audioHover }
                TapHandler {
                    enabled: !root.recording && !root.busy
                    onTapped: root.withAudio = !root.withAudio
                }
            }

            Repeater {
                model: [
                    {mode: "window", icon: "󰖲", title: "Janela", detail: "Escolher uma janela visível"},
                    {mode: "screen", icon: "󰍹", title: "Tela inteira", detail: "Monitor em foco"},
                    {mode: "selection", icon: "󰒉", title: "Seleção", detail: "Marcar uma área na tela"}
                ]


                delegate: Rectangle {
                    required property var modelData
                    width: 274
                    height: 38
                    radius: root.theme.radiusMd
                    color: rowHover.hovered && !root.recording && !root.busy
                           ? root.theme.surfaceHover : root.theme.cardBackground
                    opacity: root.recording || root.busy ? 0.45 : 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10
                        Text {
                            width: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            color: root.theme.blue
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 15
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: modelData.title
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.detail
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 9
                            }
                        }
                    }
                    HoverHandler { id: rowHover }
                    TapHandler {
                        enabled: !root.recording && !root.busy
                        onTapped: root.startRequested(modelData.mode, root.withAudio)
                    }

                }
            }

            Rectangle {
                width: 274
                height: 30
                radius: root.theme.radiusSm
                visible: root.recording
                color: stopHover.hovered ? root.theme.red : root.theme.surface
                Text {
                    anchors.centerIn: parent
                    text: root.busy ? "Finalizando…" : "Parar gravação"
                    color: stopHover.hovered ? root.theme.backgroundOpaque : root.theme.red
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                HoverHandler { id: stopHover }
                TapHandler { enabled: !root.busy; onTapped: root.stopRequested() }
            }

            Text {
                width: 274
                visible: root.errorText.length > 0 || root.savedPath.length > 0
                text: root.errorText.length > 0 ? root.errorText : "Salvo: " + root.savedPath
                color: root.errorText.length > 0 ? root.theme.red : root.theme.green
                font.family: root.theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideMiddle
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.visible = false
    }
}
