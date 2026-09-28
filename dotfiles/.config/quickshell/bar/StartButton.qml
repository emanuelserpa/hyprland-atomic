import QtQuick
import Quickshell
import qs.components

Item {
    id: root

    required property var theme

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: pill.implicitWidth
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme
        text: "󰕱"
        tooltipText: "Menu iniciar"

        StartMenu {
            id: menu
            theme: root.theme
            target: pill
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                menu.visible = !menu.visible
        }
    }
}
