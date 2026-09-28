import QtQuick
import Quickshell
import qs.components

FloatingWindow {
    id: root

    required property var theme
    property var printerData: ({})
    property string errorText: ""
    property bool busy: false
    readonly property var jobs: printerData?.jobs ?? []

    signal refreshRequested()
    signal cancelRequested(string jobId)

    title: "Fila de impressão"
    implicitWidth: 700
    implicitHeight: 500
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusPopup
        color: root.theme.background
        border.width: 1
        border.color: root.theme.borderPopup

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Row {
                width: parent.width
                height: 40
                spacing: 12

                Text {
                    width: 27
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰐪"
                    color: root.theme.accent
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 20
                }

                Column {
                    width: parent.width - 151
                    spacing: 3

                    Text {
                        text: "Fila de impressão"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.jobs.length === 1 ? "1 documento pendente"
                             : root.jobs.length + " documentos pendentes"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 100
                    height: 30
                    radius: 7
                    color: refreshHover.hovered ? root.theme.cardBackgroundHover
                                                : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: root.theme.borderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "Atualizar"
                        color: root.theme.blue
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                    }

                    HoverHandler { id: refreshHover }
                    TapHandler { onTapped: root.refreshRequested() }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.borderSubtle
            }

            Text {
                id: bufferHint
                visible: root.jobs.length > 0
                width: parent.width
                text: "Cancelar limpa a fila; páginas já enviadas terminam no buffer da impressora."
                wrapMode: Text.Wrap
                color: root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 9
            }

            Text {
                visible: root.errorText.length > 0
                width: parent.width
                text: root.errorText
                wrapMode: Text.Wrap
                color: root.theme.red
                font.family: root.theme.fontFamily
                font.pixelSize: 10
            }

            Item {
                width: parent.width
                height: parent.height - 65 - (bufferHint.visible ? bufferHint.height + 12 : 0) - (root.errorText.length > 0 ? 24 : 0)

                Column {
                    anchors.centerIn: parent
                    visible: root.jobs.length === 0
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰈙"
                        color: root.theme.accent
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 30
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Nenhum documento na fila"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                    }
                }

                Flickable {
                    id: list
                    anchors.fill: parent
                    visible: root.jobs.length > 0
                    clip: true
                    contentWidth: width
                    contentHeight: rows.implicitHeight

                    WheelKinetic { target: list }

                    Column {
                        id: rows
                        width: list.width
                        spacing: 3

                        Repeater {
                            model: root.jobs

                            delegate: Rectangle {
                                required property var modelData
                                width: rows.width
                                height: 54
                                radius: 7
                                color: rowHover.hovered ? root.theme.cardBackgroundHover
                                                        : root.theme.cardBackgroundSubtle

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        width: 26
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰈙"
                                        color: root.theme.blue
                                        font.family: root.theme.nerdFontFamily
                                        font.pixelSize: 17
                                    }

                                    Column {
                                        width: parent.width - 135
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            width: parent.width
                                            text: String(modelData.title ?? modelData.id ?? "Documento")
                                            elide: Text.ElideRight
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            text: String(modelData.printer ?? "")
                                                  + (modelData.owner ? " · " + modelData.owner : "")
                                                  + (modelData.id ? " · " + modelData.id : "")
                                                  + (String(modelData.rank ?? "") === "active" ? " · ● imprimindo" : "")
                                            elide: Text.ElideRight
                                            color: String(modelData.rank ?? "") === "active" ? root.theme.orange : root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        width: 68
                                        height: 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 6
                                        color: cancelHover.hovered ? root.theme.cardBackgroundHover
                                                                   : root.theme.cardBackgroundSubtle
                                        border.width: 1
                                        border.color: root.theme.red

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancelar"
                                            color: root.theme.red
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                        }

                                        HoverHandler { id: cancelHover }
                                        TapHandler {
                                            enabled: !root.busy
                                            onTapped: root.cancelRequested(String(modelData.id ?? ""))
                                        }
                                    }
                                }

                                HoverHandler { id: rowHover }
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
