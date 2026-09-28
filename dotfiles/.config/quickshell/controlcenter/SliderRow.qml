import QtQuick

Item {
    id: root

    required property var theme
    property string icon: ""
    property real value: 0
    property real maximum: 1
    property string valueText: ""
    property color accent: theme.blue
    property bool available: true

    signal valueRequested(real value)

    implicitHeight: 42

    readonly property real step: root.maximum > 10 ? 5 : 0.05

    function stepDelta(up) {
        if (!root.available) return
        var next = up ? (root.value + root.step) : (root.value - root.step)
        if (root.maximum <= 10) {
            next = Math.round(next * 100) / 100
        }
        next = Math.max(0, Math.min(root.maximum, next))
        root.valueRequested(next)
    }

    WheelHandler {
        enabled: root.available
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (event.angleDelta.y !== 0)
                root.stepDelta(event.angleDelta.y > 0)
        }
    }

    Text {
        id: iconLabel
        width: 30
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.available ? root.accent : root.theme.grey
        font.family: root.theme.nerdFontFamily
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        id: trackArea
        anchors.left: iconLabel.right
        anchors.leftMargin: 8
        anchors.right: valueLabel.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 24

        Rectangle {
            id: track
            width: parent.width
            height: 7
            anchors.verticalCenter: parent.verticalCenter
            radius: 4
            color: root.theme ? root.theme.cardBackgroundActive : Qt.rgba(69/255,71/255,90/255,0.65)

            Rectangle {
                id: fill
                width: parent.width * Math.max(0, Math.min(1, root.value / root.maximum))
                height: parent.height
                radius: parent.radius
                color: root.available ? root.accent : root.theme.grey
            }

            Rectangle {
                width: 11
                height: 11
                radius: 5.5
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width, fill.width - width / 2))
                color: root.theme.foreground
                border.width: 2
                border.color: root.accent
                visible: root.available && (trackMouse.containsMouse || trackMouse.pressed)
            }
        }

        MouseArea {
            id: trackMouse
            anchors.fill: parent
            enabled: root.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function apply(mouseX) {
                const ratio = Math.max(0, Math.min(1, mouseX / width))
                root.valueRequested(ratio * root.maximum)
            }

            onPressed: function(mouse) { apply(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    apply(mouse.x)
            }
            onWheel: function(wheel) {
                if (wheel.angleDelta.y !== 0)
                    root.stepDelta(wheel.angleDelta.y > 0)
            }
        }
    }

    Text {
        id: valueLabel
        width: 46
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.valueText
        color: root.available ? root.theme.offWhite : root.theme.grey
        font.family: root.theme.fontFamily
        font.pixelSize: 10
        horizontalAlignment: Text.AlignRight
    }
}
