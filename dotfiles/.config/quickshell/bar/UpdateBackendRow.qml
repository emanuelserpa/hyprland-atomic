import QtQuick

Rectangle {
    id: root

    required property var theme
    property string icon: "󰏗"
    property string title: "Backend"
    property string subtitle: ""
    property color accentColor: theme.blue
    property string statusText: "0"
    property color statusColor: accentColor

    signal runRequested()

    height: 39
    radius: 7
    color: rowHover.hovered
           ? Qt.rgba(69/255,71/255,90/255,0.34)
           : "transparent"

    Row {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 7

        Text {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.accentColor
            font.family: root.theme.nerdFontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            width: parent.width - 20 - statusBlock.width - runButton.width - 21
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

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

        Text {
            id: statusBlock
            width: 48
            anchors.verticalCenter: parent.verticalCenter
            text: root.statusText
            color: root.statusColor
            font.family: root.theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            id: runButton
            width: 25
            height: 25
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: runHover.hovered
                   ? Qt.rgba(69/255,71/255,90/255,0.65)
                   : Qt.rgba(49/255,50/255,68/255,0.34)

            Text {
                anchors.centerIn: parent
                text: ""
                color: root.accentColor
                font.family: root.theme.nerdFontFamily
                font.pixelSize: 9
            }

            HoverHandler { id: runHover }
            TapHandler { onTapped: root.runRequested() }
        }
    }

    HoverHandler { id: rowHover }
}
