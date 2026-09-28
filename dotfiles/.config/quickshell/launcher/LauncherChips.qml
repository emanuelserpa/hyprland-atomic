import QtQuick

Item {
    id: root

    required property var palette

    property color launcherForeground: palette.foreground
    property color launcherMuted: palette.grey
    property color launcherBlue: palette.blue
    property color launcherSecondary: palette.offWhite
    property color launcherCyan: palette.cyan
    property color launcherOrange: palette.orange
    property color launcherYellow: palette.yellow
    property color launcherRed: palette.red
    property color launcherGreen: palette.green
    property color launcherPink: palette.pink

    property bool fileMode: false
    property bool clipboardMode: false
    property bool windowMode: false
    property bool actionMode: false
    property bool emojiMode: false
    property bool killMode: false
    property bool commandMode: false
    property bool calcMode: false

    signal chipClicked(string prefix, bool isActive)

    width: parent ? parent.width : 0
    height: 34

    Row {
        anchors.centerIn: parent
        spacing: 6

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "↑↓"
                color: root.launcherMuted
                font.family: root.palette.fontFamily
                font.pixelSize: 9
            }

            Text {
                text: "↵"
                color: root.launcherMuted
                font.family: root.palette.fontFamily
                font.pixelSize: 9
            }
        }

        Rectangle {
            width: 1
            height: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(88/255, 91/255, 112/255, 0.4)
        }

        Repeater {
            model: [
                { prefix: "@", label: "@ arquivos", active: root.fileMode, color: root.launcherBlue },
                { prefix: "#", label: "# clipboard", active: root.clipboardMode, color: root.launcherSecondary },
                { prefix: "~", label: "~ janelas", active: root.windowMode, color: root.launcherCyan },
                { prefix: ":", label: ": config", active: root.actionMode, color: root.launcherOrange },
                { prefix: ";", label: "; emoji", active: root.emojiMode, color: root.launcherYellow },
                { prefix: "!", label: "! kill", active: root.killMode, color: root.launcherRed },
                { prefix: ">", label: "> cmd", active: root.commandMode, color: root.launcherGreen },
                { prefix: "=", label: "= calc", active: root.calcMode, color: root.launcherPink }
            ]

            delegate: Rectangle {
                id: chipRect
                required property var modelData

                width: chipText.implicitWidth + 10
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                radius: 6

                color: chipHover.hovered
                       ? Qt.rgba(69/255, 71/255, 90/255, 0.45)
                       : (modelData.active ? Qt.rgba(49/255, 50/255, 68/255, 0.7) : "transparent")

                border.width: modelData.active ? 1 : 0
                border.color: modelData.active
                              ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.45)
                              : "transparent"

                HoverHandler {
                    id: chipHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.chipClicked(modelData.prefix, modelData.active)
                }

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData.label
                    color: modelData.active
                           ? modelData.color
                           : (chipHover.hovered ? root.launcherForeground : root.launcherMuted)
                    font.family: root.palette.fontFamily
                    font.pixelSize: 9
                    font.weight: modelData.active ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
