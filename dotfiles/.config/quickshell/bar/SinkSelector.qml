import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property var sinks: []
    property var selectedSink: null

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 6

    implicitWidth: 320
    implicitHeight: Math.min(340, listColumn.implicitHeight + 12)

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.theme.background
        border.width: 1
        border.color: root.theme.surfaceHover

        Flickable {
            id: sinkList
            anchors.fill: parent
            anchors.margins: 6
            contentWidth: width
            contentHeight: listColumn.implicitHeight
            clip: true

            WheelKinetic { target: sinkList }

            Column {
                id: listColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.sinks

                    delegate: Rectangle {
                        required property var modelData

                        width: listColumn.width
                        height: 42
                        radius: 5

                        color: modelData === root.selectedSink
                               ? Qt.rgba(108/255,99/255,187/255,0.35)
                               : rowHover.hovered
                                 ? Qt.rgba(69/255,71/255,90/255,0.70)
                                 : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 9

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData === root.selectedSink ? "󰓃" : "󰓄"
                                color: modelData === root.selectedSink
                                       ? root.theme.green
                                       : root.theme.cyan
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 40
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.description
                                          || modelData.nickname
                                          || modelData.name
                                          || "Output de áudio"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.name || ""
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        HoverHandler { id: rowHover }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                Pipewire.preferredDefaultAudioSink = modelData
                                root.visible = false
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
