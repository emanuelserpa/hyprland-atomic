import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.WindowManager

Item {
    id: root
    required property var theme
    implicitWidth: row.implicitWidth
    implicitHeight: 29

    property real wheelAccumulator: 0
    property bool wheelGestureLocked: false

    readonly property var defaultIcons: [
        "󰖟 ₁", " ₂", "󰭹 ₃", "󰎆 ₄", "󰉋 ₅",
        "󰈙 ₆", " ₇", "󰊗 ₈", "󰅩 ₉", " ₁₀"
    ]

    // labwc exposes ext-workspace through Quickshell.WindowManager.
    // Only the active desktop is shown (Hyprland-style minimalism);
    // the model holds live Windowset objects so the highlight follows
    // activation. Static fallback below covers a missing protocol.
    property int labwcDesktops: 10
    readonly property bool hyprlandActive:
        (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase().split(":").includes("hyprland")

    // User icons from workspaces.json (hot-reloads on save).
    // Missing/empty slots fall back to the defaults above.
    property var customIcons: []

    function reloadIcons() {
        try {
            const obj = JSON.parse(iconsFile.text())
            const arr = obj && obj.icons
            if (Array.isArray(arr)) {
                const out = []
                for (let i = 0; i < Math.min(10, arr.length); i++) {
                    const s = String(arr[i] ?? "").trim()
                    out.push(s.length > 0 ? s : root.defaultIcons[i])
                }
                root.customIcons = out
                return
            }
        } catch (e) {}
        root.customIcons = []
    }

    readonly property var icons: {
        const out = root.defaultIcons.slice()
        for (let i = 0; i < root.customIcons.length && i < out.length; i++)
            out[i] = root.customIcons[i]
        return out
    }

    FileView {
        id: iconsFile
        path: Quickshell.shellDir + "/workspaces.json"
        watchChanges: true
        printErrors: false
        onLoadedChanged: root.reloadIcons()
        onFileChanged: {
            iconsFile.reload()
            root.reloadIcons()
        }
    }

    Component.onCompleted: root.reloadIcons()

    readonly property var hyprlandVisibleWorkspaces:
        Hyprland.workspaces.values.filter(function(workspace) {
            return workspace.id >= 1
                   && workspace.id <= root.icons.length
                   && (workspace.active || (workspace.toplevels && workspace.toplevels.values.length > 0))
        }).sort(function(a, b) { return a.id - b.id })

    readonly property var labwcLiveWorkspaces:
        WindowManager.windowsets.filter(function(workspace) {
            return workspace.shouldDisplay && /^[0-9]+$/.test(workspace.name)
                   && Number(workspace.name) >= 1 && Number(workspace.name) <= root.icons.length
        }).sort(function(a, b) { return Number(a.name) - Number(b.name) })

    // Fallback if the compositor does not expose ext-workspace.
    readonly property var labwcVisibleWorkspaces: {
        if (root.labwcLiveWorkspaces.length > 0)
            return root.labwcLiveWorkspaces
        const n = Math.max(1, Math.min(root.labwcDesktops, root.icons.length))
        const out = []
        for (let i = 1; i <= n; i++)
            out.push({ id: i })
        return out
    }

    readonly property var visibleWorkspaces:
        root.hyprlandActive ? root.hyprlandVisibleWorkspaces : root.labwcVisibleWorkspaces

    function workspaceObject(n) {
        return root.hyprlandActive
            ? (Hyprland.workspaces.values.find(w => w.id === n) ?? null)
            : (root.labwcLiveWorkspaces.find(w => Number(w.name) === n) ?? null)
    }

    function focusWorkspace(selector) {
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/compositor-dispatch.sh",
            "workspace",
            String(selector)
        ])
    }

    Timer {
        id: wheelUnlock
        interval: 240
        repeat: false
        onTriggered: {
            root.wheelGestureLocked = false
            root.wheelAccumulator = 0
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.visibleWorkspaces

            delegate: Rectangle {
                required property var modelData
                // Hyprland workspaces carry a numeric id; labwc Windowsets
                // carry the desktop number in their name.
                property int workspaceNumber: root.hyprlandActive
                    ? modelData.id : Number(modelData.name)
                property var ws: modelData
                property bool active: ws !== null ? ws.active : false
                property bool urgent: ws !== null ? ws.urgent : false

                width: Math.max(26, label.implicitWidth + 12)
                height: root.theme ? root.theme.pillHeight : 25
                radius: root.theme ? root.theme.pillRadius : 6
                clip: true

                color: urgent ? root.theme.red
                              : active ? root.theme.accent
                              : hover.containsMouse ? (root.theme ? root.theme.pillBackgroundHover : Qt.rgba(69/255, 71/255, 90/255, 0.65))
                              : (root.theme ? root.theme.pillBackground : Qt.rgba(49/255, 50/255, 68/255, 0.50))

                border.width: 1
                border.color: urgent ? root.theme.red
                            : active ? root.theme.accent
                            : hover.containsMouse ? (root.theme ? root.theme.pillBorderHover : Qt.rgba(88/255, 91/255, 112/255, 0.55))
                            : (root.theme ? root.theme.pillBorder : Qt.rgba(69/255, 71/255, 90/255, 0.35))

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.icons[parent.workspaceNumber - 1]
                    color: parent.urgent ? root.theme.backgroundOpaque
                         : parent.active ? (root.theme.isLight ? "#ffffff" : root.theme.backgroundOpaque)
                         : hover.containsMouse ? root.theme.accent
                         : (root.theme.isLight ? root.theme.foreground : root.theme.offWhite)
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        // Both Hyprland workspaces and labwc Windowsets expose
                        // activate(); static fallback pills ({id}) use the dispatcher.
                        if (parent.ws !== null && typeof parent.ws.activate === "function")
                            parent.ws.activate()
                        else
                            root.focusWorkspace(String(parent.workspaceNumber))
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            wheel.accepted = true

            if (wheel.phase === Qt.ScrollBegin) {
                root.wheelAccumulator = 0
                root.wheelGestureLocked = false
            }

            if (wheel.phase === Qt.ScrollEnd) {
                root.wheelAccumulator = 0
                root.wheelGestureLocked = false
                return
            }

            if (root.wheelGestureLocked) {
                wheelUnlock.restart()
                return
            }

            const hasPixelDelta = wheel.pixelDelta.y !== 0
            const delta = hasPixelDelta
                          ? wheel.pixelDelta.y
                          : wheel.angleDelta.y
            const threshold = hasPixelDelta ? 42 : 120

            if (delta === 0)
                return

            root.wheelAccumulator += delta

            if (Math.abs(root.wheelAccumulator) < threshold)
                return

            if (root.hyprlandActive) {
                root.focusWorkspace(root.wheelAccumulator > 0 ? "e-1" : "e+1")
            } else {
                const workspaces = root.labwcLiveWorkspaces
                const current = workspaces.findIndex(w => w.active)
                const next = current + (root.wheelAccumulator > 0 ? -1 : 1)
                if (current >= 0 && next >= 0 && next < workspaces.length
                    && workspaces[next].canActivate)
                    workspaces[next].activate()
            }
            root.wheelAccumulator = 0
            root.wheelGestureLocked = true
            wheelUnlock.restart()
        }
    }
}
