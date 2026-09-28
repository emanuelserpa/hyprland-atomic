import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property real percentage: 0
    property bool charging: false
    property bool plugged: false
    property real watts: 0
    property real secondsRemaining: 0
    property string stateText: "Bateria"
    property var profileData: ({})
    property bool profileBusy: false
    property string profileError: ""
    property var chargeLimitData: ({})
    property bool chargeLimitBusy: false
    property string chargeLimitError: ""

    signal profileRequested(string profile)
    signal chargeLimitRequested(string mode)

    readonly property bool chargeLimitVisible: root.chargeLimitData?.available !== false

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 260
    implicitHeight: root.chargeLimitVisible ? 240 : 184
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true


    function iconFor(p) {
        if (p < 15) return "󰁺"
        if (p < 35) return "󰁼"
        if (p < 60) return "󰁾"
        if (p < 85) return "󰂀"
        return "󰁹"
    }

    function timeText(sec) {
        if (!sec || sec <= 0) {
            return root.plugged ? "Completa" : "Calculando..."
        }
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + " min"
    }

    readonly property color levelColor:
        percentage <= 15 ? theme.red
        : percentage <= 30 ? theme.yellow
        : charging ? theme.cyan
        : theme.green

    onVisibleChanged: {
        if (visible)
            card.forceActiveFocus()
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Cabeçalho: Ícone + Título/Status + Porcentagem
            Item {
                width: parent.width
                height: 28

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 7
                        color: root.theme.cardBackgroundHover
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.charging
                                  ? "󰂄"
                                  : (root.plugged ? "󰚥" : root.iconFor(root.percentage))
                            color: root.levelColor
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 15
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Bateria ThinkPad"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.charging
                                  ? "Carregando"
                                  : (root.plugged ? "Carga completa" : "Em uso (Bateria)")
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.percentage) + "%"
                    color: root.levelColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
            }

            // Barra fina de progresso
            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: root.theme.cardBackgroundActive

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.percentage / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.levelColor
                }
            }

            // Métricas: Tempo Restante | Consumo / Potência
            Row {
                width: parent.width
                spacing: 6

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: 46
                    radius: 8
                    color: root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰔛"
                            color: root.theme.blue
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: root.charging ? "Até 100%" : "Restante"
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                            }

                            Text {
                                text: root.timeText(root.secondsRemaining)
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: 46
                    radius: 8
                    color: root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰈐"
                            color: root.theme.cyan
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            spacing: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: root.charging ? "Potência" : "Consumo"
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                            }

                            Text {
                                text: root.watts > 0 ? (root.watts.toFixed(1) + " W") : "0.0 W"
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            // Perfil de Energia (Economia | Balanceado | Performance)
            Column {
                width: parent.width
                spacing: 5

                Row {
                    width: parent.width

                    Text {
                        text: "Perfil de Energia"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: Math.max(0, parent.width - 170); height: 1 }

                    Text {
                        text: String(root.profileData?.backend_label ?? "")
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                PowerProfileSelector {
                    theme: root.theme
                    profiles: root.profileData?.profiles ?? []
                    activeProfile: String(root.profileData?.active ?? "")
                    available: Boolean(root.profileData?.available ?? true)
                    busy: root.profileBusy
                    onProfileRequested: function(profileId) {
                        root.profileRequested(profileId)
                    }
                }

                Text {
                    visible: root.profileError.length > 0
                    width: parent.width
                    text: root.profileError
                    color: root.theme.red
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            // Limite de Carga (Eco 80% | Viagem 100%)
            Column {
                visible: root.chargeLimitVisible
                width: parent.width
                spacing: 5

                Row {
                    width: parent.width

                    Text {
                        text: "Limite de Carga"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: Math.max(0, parent.width - 195); height: 1 }

                    Text {
                        text: Number(root.chargeLimitData?.limit) === 100 ? "Viagem 100%" : "Eco 80%"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                PowerProfileSelector {
                    theme: root.theme
                    profiles: [{ id: "80", label: "Eco 80%" }, { id: "100", label: "Viagem 100%" }]
                    activeProfile: String(root.chargeLimitData?.limit ?? "")
                    available: Boolean(root.chargeLimitData?.available ?? true)
                    busy: root.chargeLimitBusy
                    onProfileRequested: function(mode) {
                        root.chargeLimitRequested(mode)
                    }
                }

                Text {
                    visible: root.chargeLimitError.length > 0
                    width: parent.width
                    text: root.chargeLimitError
                    color: root.theme.red
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
