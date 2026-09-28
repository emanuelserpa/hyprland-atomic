import QtQuick

// Etapa 1 do plano Raycast (docs/spotlight-raycast-plan.md): barra inferior
// contextual. Mostra a ação primária e a secundária do item selecionado
// (via SpotlightActionCatalog); cliques executam. Não aparece nos modos
// com preview próprio (clipboard, tema).
Item {
    id: root

    required property var palette
    property string primaryText: ""
    property string secondaryText: ""
    signal primaryClicked()
    signal secondaryClicked()

    width: parent ? parent.width : 0
    height: 34

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        height: 20

        Text {
            height: 20
            verticalAlignment: Text.AlignVCenter
            text: "↵ " + root.primaryText
            color: root.palette.foreground
            font.family: root.palette.fontFamily
            font.pixelSize: 10

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.primaryClicked()
            }
        }

        Rectangle {
            width: 1
            height: 12
            anchors.verticalCenter: parent.verticalCenter
            color: root.palette.borderSubtle
            visible: root.secondaryText.length > 0
        }

        Text {
            height: 20
            verticalAlignment: Text.AlignVCenter
            visible: root.secondaryText.length > 0
            text: "Ctrl+↵ " + root.secondaryText
            color: root.palette.foreground
            font.family: root.palette.fontFamily
            font.pixelSize: 10

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.secondaryClicked()
            }
        }
    }
}
