import QtQuick

Rectangle {
    id: root

    property var theme: null
    property color textColor: theme ? (theme.isLight ? theme.foreground : theme.offWhite) : "#bac2de"
    property alias text: label.text
    property alias fontPixelSize: label.font.pixelSize
    property alias mouseArea: mouse
    property bool highlighted: false
    property bool plain: false
    property string tooltipText: ""
    property bool tooltipOpenLeft: false
    property bool showTooltip: false

    implicitHeight: root.theme ? root.theme.pillHeight : 25
    implicitWidth: label.implicitWidth + 14
    radius: root.theme ? root.theme.pillRadius : 6
    clip: true

    color: plain
           ? (highlighted || mouse.containsMouse
              ? (root.theme ? root.theme.cardBackgroundHover : Qt.rgba(69/255, 71/255, 90/255, 0.35))
              : "transparent")
           : (highlighted || mouse.containsMouse
              ? (root.theme ? root.theme.pillBackgroundHover : Qt.rgba(69/255, 71/255, 90/255, 0.65))
              : (root.theme ? root.theme.pillBackground : Qt.rgba(49/255, 50/255, 68/255, 0.50)))

    border.width: plain ? 0 : 1
    border.color: (highlighted || mouse.containsMouse)
           ? (root.theme ? root.theme.pillBorderHover : Qt.rgba(88/255, 91/255, 112/255, 0.55))
           : (root.theme ? root.theme.pillBorder : Qt.rgba(69/255, 71/255, 90/255, 0.35))

    Timer {
        id: tooltipTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (mouse.containsMouse && root.tooltipText.length > 0) {
                root.showTooltip = true
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        textFormat: Text.PlainText
        font.family: root.theme ? root.theme.nerdFontFamily : "Noto Sans Nerd Font"
        font.pixelSize: root.theme ? root.theme.fontSize : 13
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        onContainsMouseChanged: {
            if (containsMouse && root.tooltipText.length > 0) {
                tooltipTimer.restart()
            } else {
                tooltipTimer.stop()
                root.showTooltip = false
            }
        }

        onPressedChanged: {
            if (pressed) {
                tooltipTimer.stop()
                root.showTooltip = false
            }
        }
    }

    onTooltipTextChanged: {
        if (root.tooltipText.length === 0) {
            tooltipTimer.stop()
            root.showTooltip = false
        }
    }

    onVisibleChanged: {
        if (!visible) {
            tooltipTimer.stop()
            root.showTooltip = false
        }
    }

    ToolTipBubble {
        theme: root.theme
        target: root
        text: root.tooltipText
        openLeft: root.tooltipOpenLeft
        visible: root.theme !== null && root.showTooltip && text.length > 0
    }
}
