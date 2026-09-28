pragma Singleton
import QtQuick
import Quickshell
import qs.components

// Single source of truth for system-update counts. Consumed by the
// conditional bar pill (bar/SystemUpdates.qml) and the dashboard cards,
// so checkupdates/AUR/Flatpak/Homebrew helpers run once per interval.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    CommandJson {
        id: archUpdates
        command: ["sh", "-c", Quickshell.shellDir + "/scripts/arch-updates.sh"]
        interval: 3600000
    }

    CommandJson {
        id: aurUpdates
        command: ["sh", "-c", Quickshell.shellDir + "/scripts/aur-updates.sh"]
        interval: 3600000
    }

    CommandJson {
        id: flatpakUpdates
        command: ["sh", "-c", Quickshell.shellDir + "/scripts/flatpak-updates.sh"]
        interval: 3600000
    }

    CommandJson {
        id: brewUpdates
        command: ["sh", "-c", Quickshell.shellDir + "/scripts/brew-updates.sh"]
        interval: 3600000
    }

    readonly property int archCount: Number(archUpdates.data?.count ?? 0)
    readonly property int aurCount: Number(aurUpdates.data?.count ?? 0)
    readonly property int flatpakCount: Number(flatpakUpdates.data?.count ?? 0)
    readonly property int brewCount: Number(brewUpdates.data?.count ?? 0)
    readonly property int totalUpdates: archCount + aurCount + flatpakCount + brewCount

    readonly property var repoData: archUpdates.data
    readonly property var aurData: aurUpdates.data
    readonly property var flatpakData: flatpakUpdates.data
    readonly property var brewData: brewUpdates.data

    function refreshUpdates() {
        archUpdates.refresh()
        aurUpdates.refresh()
        flatpakUpdates.refresh()
        brewUpdates.refresh()
    }
}
