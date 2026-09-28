import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property var printerData: ({})
    property string errorText: ""
    property bool busy: false

    signal refreshRequested()
    signal cancelRequested(string jobId)
    signal settingsRequested()
    signal queueRequested()

    readonly property var printers: printerData?.printers ?? []
    readonly property var jobs: printerData?.jobs ?? []

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 340
    implicitHeight: Math.min(460, 166 + printers.length * 45 + Math.min(jobs.length, 5) * 42)
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

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
            anchors.margins: 12
            spacing: 8

            Row {
                width: parent.width
                height: 30
                spacing: 8

                Text {
                    width: parent.width - 76
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Impressoras"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 30
                    height: 28
                    radius: 7
                    color: refreshHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: root.theme.blue
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: refreshHover }
                    TapHandler { onTapped: root.refreshRequested() }
                }

                Rectangle {
                    width: 30
                    height: 28
                    radius: 7
                    color: settingsHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: settingsHover }
                    TapHandler { onTapped: root.settingsRequested() }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.borderSubtle
            }

            Repeater {
                model: root.printers

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 42
                    radius: 8
                    color: root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 9

                        Text {
                            width: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰐪"
                            color: modelData.state === "stopped" || modelData.state === "unknown"
                                   ? root.theme.red
                                   : (modelData.state === "printing"
                                      ? root.theme.orange
                                      : root.theme.blue)
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 15
                        }

                        Column {
                            width: parent.width - 34
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: String(modelData.name ?? "Impressora")
                                      + (modelData.default ? " · padrão" : "")
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: String(modelData.state_text ?? "")
                                color: modelData.state === "stopped" || modelData.state === "unknown"
                                       ? root.theme.red
                                       : root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.jobs.length > 0
                text: "Fila"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: parent.width
                height: 30
                radius: 7
                color: queueHover.hovered ? root.theme.cardBackgroundHover
                                          : root.theme.cardBackgroundSubtle
                border.width: 1
                border.color: root.theme.borderSubtle

                Text {
                    anchors.centerIn: parent
                    text: "Abrir fila de impressão  ↗"
                    color: root.theme.blue
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                HoverHandler { id: queueHover }
                TapHandler { onTapped: root.queueRequested() }
            }

            Item {
                visible: root.jobs.length > 0
                width: parent.width
                height: Math.min(210, jobsColumn.implicitHeight)

                Flickable {
                    id: jobsFlick
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: jobsColumn.implicitHeight

                    WheelKinetic {
                        target: jobsFlick
                    }

                    Column {
                        id: jobsColumn
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: root.jobs

                            delegate: Rectangle {
                                required property var modelData
                                width: jobsColumn.width
                                height: 39
                                radius: 8
                                color: jobHover.hovered
                                       ? root.theme.cardBackgroundHover
                                       : root.theme.cardBackgroundSubtle
                                border.width: 1
                                border.color: root.theme.borderSubtle

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 8

                                    Column {
                                        width: parent.width - 76
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: String(modelData.title ?? modelData.id ?? "")
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: String(modelData.printer ?? "")
                                                  + (modelData.owner ? " · " + modelData.owner : "")
                                                  + (modelData.id ? " · " + modelData.id : "")
                                                  + (String(modelData.rank ?? "") === "active" ? " · ● imprimindo" : "")
                                            color: String(modelData.rank ?? "") === "active" ? root.theme.orange : root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 58
                                        height: 23
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 6
                                        color: Qt.rgba(243/255,139/255,168/255,0.10)
                                        border.width: 1
                                        border.color: Qt.rgba(243/255,139/255,168/255,0.24)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancelar"
                                            color: root.theme.red
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }

                                        TapHandler {
                                            enabled: !root.busy
                                            onTapped: root.cancelRequested(String(modelData.id ?? ""))
                                        }
                                    }
                                }

                                HoverHandler { id: jobHover }
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.jobs.length === 0
                width: parent.width
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: "Fila vazia"
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 9
                }
            }

            Text {
                visible: root.errorText.length > 0
                width: parent.width
                text: root.errorText
                color: root.theme.red
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
