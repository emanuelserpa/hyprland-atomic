import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.services

Item {
    id: root

    required property var theme

    implicitWidth: pill.implicitWidth
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    readonly property int notificationCount: NotificationState.count
    readonly property bool dnd: NotificationState.dnd
    readonly property bool hasCritical: NotificationState.hasCritical

    readonly property string notificationState: {
        const hasNotifications = notificationCount > 0

        if (dnd && hasNotifications) return "dnd-notification"
        if (dnd) return "dnd-none"
        if (hasNotifications) return "notification"
        return "none"
    }

    readonly property string notificationIcon: {
        switch (notificationState) {
        case "notification": return "󱅫"
        case "dnd-notification": return "󰂠"
        case "dnd-none": return "󰪓"
        default: return "󰂜"
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme
        text: root.notificationCount > 0 ? `${root.notificationIcon} ${root.notificationCount}` : root.notificationIcon
        textColor: {
            if (!root.theme) return "#bac2de"
            if (root.hasCritical) return root.theme.red
            if (root.dnd) return root.theme.grey
            if (root.notificationCount > 0) return root.theme.blue
            return root.theme.offWhite
        }
        highlighted: notificationPopup.visible || root.hasCritical

        tooltipText: {
            let text = root.notificationCount === 0
                       ? "Nenhuma notificação"
                       : (root.notificationCount === 1 ? "1 notificação" : root.notificationCount + " notificações")

            if (root.dnd)
                text += " • Não perturbe"

            text += " • Botão direito: DND"
            return text
        }

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                notificationPopup.toggle()
            } else if (mouse.button === Qt.RightButton) {
                NotificationState.toggleDnd()
            }
        }
    }

    Connections {
        target: NotificationState
        function onTogglePopupRequested() {
            notificationPopup.toggle()
        }
    }

    NotificationPopup {
        id: notificationPopup
        theme: root.theme
        target: pill
    }
}
