import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    property color accent: theme.blue

    signal clicked()

    implicitHeight: 54
    radius: root.theme ? root.theme.radiusLg : 10
    color: root.active
           ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
           : (hover.hovered
              ? (root.theme ? root.theme.cardBackgroundHover : Qt.rgba(69/255,71/255,90/255,0.45))
              : (root.theme ? root.theme.cardBackgroundSubtle : Qt.rgba(49/255,50/255,68/255,0.25)))
    border.width: 1
    border.color: root.active
                  ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                  : (hover.hovered
                     ? (root.theme ? root.theme.pillBorderHover : Qt.rgba(88/255,91/255,112/255,0.55))
                     : (root.theme ? root.theme.glassBorderSubtle : Qt.rgba(255/255,255/255,255/255,0.08)))
    opacity: root.available ? 1.0 : 0.48

    Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 90 } }

    Row {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 9

        Rectangle {
            width: 32
            height: 32
            radius: root.theme ? root.theme.radiusMd : 8
            anchors.verticalCenter: parent.verticalCenter
            color: root.active
                   ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                   : (root.theme.isLight ? Qt.rgba(root.theme.grey.r, root.theme.grey.g, root.theme.grey.b, 0.14) : Qt.rgba(255/255,255/255,255/255,0.06))

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? root.accent : (root.theme.isLight ? root.theme.foreground : root.theme.offWhite)
                font.family: root.theme.nerdFontFamily
                font.pixelSize: 16
            }
        }

        Column {
            width: parent.width - 43
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.title
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.subtitle
                color: root.theme.grey
                font.family: root.theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.available
        onTapped: root.clicked()
    }
}
