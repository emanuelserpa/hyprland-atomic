import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property int brightness: 0
    property bool available: false
    property string deviceName: ""

    signal brightnessRequested(real value)

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 260
    implicitHeight: 104
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
            anchors.margins: 11
            spacing: 8

            // Header: Title + Brightness Percentage Badge
            Item {
                width: parent.width
                height: 20

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: "󰃠"
                        color: root.available ? root.theme.yellow : root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Brilho"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: Math.max(34, valueText.implicitWidth + 12)
                    radius: 9
                    color: root.available ? Qt.rgba(249/255, 226/255, 175/255, 0.18) : Qt.rgba(49/255, 50/255, 68/255, 0.40)
                    border.width: 1
                    border.color: root.available ? Qt.rgba(249/255, 226/255, 175/255, 0.35) : Qt.rgba(69/255, 71/255, 90/255, 0.30)

                    Text {
                        id: valueText
                        anchors.centerIn: parent
                        text: root.available ? root.brightness + "%" : "--%"
                        color: root.available ? root.theme.yellow : root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            // Slider Section
            Item {
                id: trackArea
                width: parent.width
                height: 24

                Rectangle {
                    id: track
                    width: parent.width
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 3
                    color: Qt.rgba(69/255, 71/255, 90/255, 0.45)

                    Rectangle {
                        id: fill
                        width: parent.width * Math.max(0, Math.min(1, root.brightness / 100))
                        height: parent.height
                        radius: parent.radius
                        color: root.available ? root.theme.yellow : root.theme.grey
                    }

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        x: Math.max(0, Math.min(parent.width - width, fill.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.theme.foreground
                        border.width: 2
                        border.color: root.available ? root.theme.yellow : root.theme.grey
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.available
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    property bool userDragging: false

                    function apply(mouseX) {
                        if (!userDragging || width <= 0)
                            return

                        const clampedX = Math.max(0, Math.min(width, mouseX))
                        const value = Math.max(1, Math.min(100, (clampedX / width) * 100))
                        root.brightnessRequested(value)
                    }

                    onPressed: function(mouse) {
                        userDragging = true
                        apply(mouse.x)
                    }

                    onPositionChanged: function(mouse) {
                        if (userDragging && pressed)
                            apply(mouse.x)
                    }

                    onReleased: userDragging = false
                    onCanceled: userDragging = false
                }
            }

            // Footer Subtitle / Info
            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.right: hintText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.available
                          ? (root.deviceName.length > 0 ? root.deviceName : "Backlight")
                          : "Backlight indisponível"
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }

                Text {
                    id: hintText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Scroll ±5%"
                    color: root.theme.grey
                    opacity: 0.72
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
