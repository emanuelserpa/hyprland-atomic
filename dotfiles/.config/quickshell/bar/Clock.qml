import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root
    required property var theme
    property bool plain: true
    property bool active: false

    signal toggleDashboardRequested()

    implicitWidth: pill.implicitWidth
    implicitHeight: root.theme ? root.theme.pillHeight : 25

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // SystemClock sleeps until the next minute boundary on the monotonic
    // clock, which does not advance during suspend: after resume it can
    // stay stale for the whole suspended duration. Periodically restart
    // its internal timer so it resyncs shortly after resume.
    Timer {
        interval: 20000
        repeat: true
        running: true
        onTriggered: {
            clock.enabled = false
            clock.enabled = true
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        theme: root.theme
        plain: root.plain
        highlighted: root.active
        textColor: IdleState.inhibited ? (root.theme ? root.theme.yellow : "#f9e2af") : (root.theme ? root.theme.blue : "#89b4fa")
        text: " " + Qt.formatDateTime(clock.date, "dd/MM") +
              "   " + Qt.formatDateTime(clock.date, "HH:mm") +
              (IdleState.inhibited ? " •" : "")

        tooltipText: IdleState.inhibited
                     ? "Cafeína ativa • Botão direito para desativar"
                     : "Relógio • Botão direito: Cafeína (inibir suspensão)"

        mouseArea.onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                root.toggleDashboardRequested()
            else if (mouse.button === Qt.RightButton)
                IdleState.inhibited = !IdleState.inhibited
        }
    }
}
