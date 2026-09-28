import QtQuick
import Quickshell
import qs.components
import qs.services

// Conditional updates pill: only visible while updates are pending,
// following the Media/Submap pattern to keep the bar glanceable.
Pill {
    id: root

    visible: UpdateState.totalUpdates > 0
    text: "󰚰 " + UpdateState.totalUpdates
    highlighted: popup.visible
    tooltipText: "Atualizações disponíveis • Clique para ver"

    mouseArea.onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton)
            popup.visible = !popup.visible
    }

    SystemUpdatePopup {
        id: popup
        theme: root.theme
        target: root
        repoData: UpdateState.repoData
        aurData: UpdateState.aurData
        flatpakData: UpdateState.flatpakData
        brewData: UpdateState.brewData

        onRefreshRequested: UpdateState.refreshUpdates()

        onUpdateRequested: function(backend) {
            popup.visible = false
            Quickshell.execDetached([
                "bash",
                Quickshell.shellDir + "/scripts/run-update-terminal.sh",
                backend
            ])
        }
    }
}
