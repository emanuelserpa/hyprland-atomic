import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property real temperature: 0
    property string sensor: ""

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 250
    implicitHeight: 124
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    readonly property color tempColor:
        temperature >= 80 ? theme.red
        : temperature >= 70 ? theme.orange
        : temperature >= 60 ? theme.yellow
        : theme.cyan

    readonly property string statusText:
        temperature >= 80 ? "Crítica"
        : temperature >= 70 ? "Elevada"
        : temperature >= 60 ? "Média"
        : "Normal"

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
        }
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent

        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 7

            // Top Header: Title + Dynamic Status Pill
            Item {
                width: parent.width
                height: 20

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: "󰔏"
                        color: root.tempColor
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Temperatura CPU"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: Math.max(36, statusBadgeText.implicitWidth + 12)
                    radius: 9
                    color: Qt.rgba(root.tempColor.r, root.tempColor.g, root.tempColor.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(root.tempColor.r, root.tempColor.g, root.tempColor.b, 0.35)

                    Text {
                        id: statusBadgeText
                        anchors.centerIn: parent
                        text: root.statusText
                        color: root.tempColor
                        font.family: root.theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }

            // Big Metric Display + Sensor Name
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.temperature) + "°C"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sensor.length > 0 ? root.sensor : "Sensor auto"
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            // Sleek 4px Temperature Gauge
            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(69/255, 71/255, 90/255, 0.45)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.temperature / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.tempColor

                    Behavior on width {
                        enabled: root.theme.qmlAnimationsEnabled
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }
            }

            // Dual Telemetry Micro-Cards
            Row {
                width: parent.width
                height: 34
                spacing: 6

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: parent.height
                    radius: 7
                    color: root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "ESTADO"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.statusText
                            color: root.tempColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: parent.height
                    radius: 7
                    color: root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "ALERTA"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "80°C"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
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
