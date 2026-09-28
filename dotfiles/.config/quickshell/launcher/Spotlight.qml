pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import qs
import qs.bar
import qs.components
import qs.services

PanelWindow {
    id: root

    // labwc only transfers keyboard focus to layer surfaces with explicit
    // exclusive interactivity; PanelWindow.focusable alone is not enough.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: true
    visible: false
    aboveWindows: true

    Theme { id: palette }

    SessionActionsPopup {
        id: sessionConfirmation
        theme: palette
        target: card
        ownerActive: root.visible
        confirmationOnly: true

        onActionRequested: function(action) {
            root.closeLauncher()
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/session-action.sh", action])
        }
        onVisibleChanged: {
            if (!visible && root.visible)
                searchInput.forceActiveFocus()
        }
    }

    readonly property color launcherForeground: palette.foreground
    readonly property color launcherSecondary: palette.offWhite
    readonly property color launcherMuted: palette.grey
    readonly property color launcherBackground: palette.background
    readonly property color launcherSurface: palette.surface
    readonly property color launcherSurfaceHover: palette.surfaceHover
    readonly property color launcherBlue: palette.blue
    readonly property color launcherGreen: palette.green
    readonly property color launcherPink: palette.pink
    readonly property color launcherOrange: palette.orange
    readonly property color launcherYellow: palette.yellow
    readonly property color launcherRed: palette.red
    readonly property color launcherCyan: palette.cyan

    property string query: searchInput.text
    // Open-latency budget guard (validate.sh warns past 150ms).
    property double openRequestedAt: 0
    // Raycast-style emoji grid cursor (emojiMode only).
    property int emojiIndex: 0
    // Etapa 1 Raycast: barra inferior contextual (só com digitação; vazio mostra os modos).
    readonly property bool actionBarVisible: !root.clipboardMode && !root.themeMode && root.query.trim().length > 0 && root.selectedResult !== null
    // Etapa 2 Raycast: painel de ações.
    property bool actionPanelOpen: false
    property int actionIndex: 0
    property string panelBaseQuery: ""
    readonly property string actionBarPrimary: {
        const a = actionRegistry.primaryAction(root.selectedResult)
        return a ? String(a.title ?? "") : ""
    }
    readonly property string actionBarSecondary: {
        const a = actionRegistry.secondaryAction(root.selectedResult)
        return a ? String(a.title ?? "") : ""
    }
    property int selectedIndex: results.length > 0
                                ? Math.min(resultList.currentIndex, results.length - 1)
                                : -1
    readonly property var selectedResult: (selectedIndex >= 0 && selectedIndex < results.length)
                                         ? results[selectedIndex]
                                         : null

    readonly property bool commandMode: query.trim().startsWith(">")
    readonly property bool calcMode: query.trim().startsWith("=")
    readonly property bool fileMode: query.trim().startsWith("@")
    readonly property bool clipboardMode: query.trim().startsWith("#")
    readonly property bool actionMode: query.trim().startsWith(":")
    readonly property bool themeMode: query.trim().startsWith(":tema") || query.trim().startsWith(":theme") || query.trim().startsWith(":config")
    readonly property bool emojiMode: query.trim().startsWith(";")
    readonly property bool killMode: query.trim().startsWith("!")
    readonly property bool windowMode: query.trim().startsWith("~")

    property var appUsage: ({})
    property string clipboardSelectedIdBeforeRefresh: ""

    readonly property var results: resultModel.normalizeAll(buildResults(query), undefined, actionRegistry)

    // IPC entry points for compositors without GlobalShortcut support
    // (e.g. labwc keybinds call `quickshell ipc call spotlight <fn>`).
    IpcHandler {
        target: "spotlight"

        function toggle(): void { root.toggleLauncher() }        function open(): void { root.openLauncher() }
        function clipboard(): void { root.openWithPrefix("#") }
        function actions(): void { root.openWithPrefix(":") }
        function theme(): void { root.openWithPrefix(":tema ") }
        function config(): void { root.openWithPrefix(":tema ") }
        function emoji(): void { root.openWithPrefix(";") }
        function kill(): void { root.openWithPrefix("!") }
        function windows(): void { root.openWithPrefix("~") }
    }

    SpotlightActions {
        id: actionCatalog
        palette: palette
    }

    // Etapa 0 Raycast: catálogo declarativo de ações (sem executar nada).
    SpotlightActionCatalog {
        id: actionRegistry
    }

    SpotlightSearch {
        id: search
    }

    SpotlightResult {
        id: resultModel
    }

    SpotlightSearchController {
        id: searchController
        searchLogic: search
        normalizer: resultModel
        actions: actionRegistry
        commandsCatalog: actionCatalog
    }

    SpotlightClipboard {
        id: clipboard
        active: root.clipboardMode
        visibleResults: root.results
    }

    SpotlightModes {
        id: modes
    }

    Connections {
        target: clipboard

        function onRestoreSucceeded() {
            if (clipboard.stayOpenOnce) {
                clipboard.stayOpenOnce = false
                return
            }
            if (root.visible && root.clipboardMode)
                root.closeLauncher()
        }

        function onItemsReplacing() {
            const selected = root.selectedResult
            root.clipboardSelectedIdBeforeRefresh = selected && selected.kind === "clipboard"
                                                    ? String(selected.clipId) : ""
        }

        function onItemsReplaced() {
            const selectedId = root.clipboardSelectedIdBeforeRefresh
            root.clipboardSelectedIdBeforeRefresh = ""
            if (!selectedId || !root.visible || !root.clipboardMode)
                return
            const index = root.results.findIndex(item =>
                item.kind === "clipboard" && String(item.clipId) === selectedId)
            if (index >= 0)
                resultList.currentIndex = index
        }
    }


    function getActionModeTitle(rawQuery) {
        const q = String(rawQuery ?? "").trim().toLowerCase()
        if (q.startsWith(":tema") || q.startsWith(":theme")) return "Temas"
        if (q.startsWith(":tela")) return "Tela & Energia"
        if (q.startsWith(":luz") || q.startsWith(":night") || q.startsWith(":display")) return "Luz Noturna"
        if (q.startsWith(":energia") || q.startsWith(":power") || q.startsWith(":bateria")) return "Energia"
        if (q.startsWith(":conexoes") || q.startsWith(":conex") || q.startsWith(":rede") || q.startsWith(":net")) return "Conexões"
        if (q.startsWith(":sistema") || q.startsWith(":system")) return "Sistema & Sessão"
        if (q.startsWith(":sessao") || q.startsWith(":session")) return "Sessão"
        return "Configurações"
    }


    function buildResults(rawQuery) {
        const trimmed = String(rawQuery ?? "").trim()

        if (trimmed.startsWith("@")) {
            const q = trimmed.slice(1).trim()
            if (q.length === 0) {
                return [{
                    kind: "hint",
                    title: "Arquivos",
                    subtitle: "Digite depois de @ para procurar em sua pasta pessoal",
                    icon: "󰈔"
                }]
            }

            return modes.fileItems.map(item => ({
                kind: "file",
                title: item.name,
                subtitle: item.parent,
                icon: item.is_dir ? "󰉋" : "󰈔",
                path: item.path
            }))
        }

        if (trimmed.startsWith("#")) {
            const q = search.normalize(trimmed.slice(1))

            if (!clipboard.available) {
                return [{
                    kind: "hint",
                    title: "Clipboard indisponível",
                    subtitle: clipboard.error.length > 0 ? clipboard.error : "wl-clipboard não disponível",
                    icon: "󰅇"
                }]
            }

            const values = clipboard.items
                .filter(item => q.length === 0
                    || search.normalize(item.preview).includes(q)
                    || search.normalize(item.fullText).includes(q)
                )
                .slice(0, 50)

            if (values.length === 0) {
                return [{
                    kind: "hint",
                    title: !clipboard.loaded
                           ? "Carregando clipboard…"
                           : "Clipboard vazio",
                    subtitle: !clipboard.loaded
                              ? "Carregando histórico do clipboard"
                              : "Nenhum item correspondente",
                    icon: "󰅇"
                }]
            }

            return values.map(item => ({
                kind: "clipboard",
                title: item.preview.length > 0 ? item.preview : "(conteúdo sem texto)",
                subtitle: String(item.subtitle ?? "Copiar para o clipboard")
                          + (!clipboard.fresh ? " · atualizando…" : "")
                          + (String(item.type ?? "") === "image" ? " · Enter para restaurar" : ""),
                icon: String(item.icon ?? "󰅇"),
                clipId: item.id,
                clipSignature: String(item.signature ?? ""),
                clipType: String(item.type ?? "text"),
                thumbnail: String(clipboard.thumbs[String(item.id)] ?? ""),
                mime: String(item.mime ?? ""),
                cached: !clipboard.fresh,
                fullText: String(item.fullText ?? item.preview ?? ""),
                lineCount: Number(item.lineCount ?? 1),
                charCount: Number(item.charCount ?? 0)
            }))
        }

        if (trimmed.startsWith(":tema") || trimmed.startsWith(":theme")) {
            const prefix = trimmed.startsWith(":tema") ? ":tema" : ":theme"
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.themeActions().filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":tela")) {
            const q = search.normalize(trimmed.slice(5).trim())
            return actionCatalog.nightlightActions().concat(actionCatalog.energyActions()).filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":luz") || trimmed.startsWith(":night") || trimmed.startsWith(":display")) {
            const prefix = trimmed.startsWith(":luz") ? ":luz" : (trimmed.startsWith(":night") ? ":night" : ":display")
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.nightlightActions().filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":energia") || trimmed.startsWith(":power") || trimmed.startsWith(":bateria")) {
            const prefix = trimmed.startsWith(":energia") ? ":energia" : (trimmed.startsWith(":power") ? ":power" : ":bateria")
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.energyActions().filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":conexoes") || trimmed.startsWith(":conex") || trimmed.startsWith(":rede") || trimmed.startsWith(":net")) {
            const prefix = trimmed.startsWith(":conexoes") ? ":conexoes" : (trimmed.startsWith(":conex") ? ":conex" : (trimmed.startsWith(":rede") ? ":rede" : ":net"))
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.connectionActions().filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":sistema") || trimmed.startsWith(":system")) {
            const prefix = trimmed.startsWith(":sistema") ? ":sistema" : ":system"
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.systemActionsList().concat(actionCatalog.sessionActions()).filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":sessao") || trimmed.startsWith(":session")) {
            const prefix = trimmed.startsWith(":sessao") ? ":sessao" : ":session"
            const q = search.normalize(trimmed.slice(prefix.length).trim())
            return actionCatalog.sessionActions().filter(item =>
                q.length === 0
                || search.normalize(item.title).includes(q)
                || search.normalize(item.subtitle).includes(q)
            )
        }

        if (trimmed.startsWith(":")) {
            return searchController.searchActions(trimmed.slice(1).trim())
        }

        if (trimmed.startsWith(";")) {
            const q = search.normalize(trimmed.slice(1))

            if (!modes.emojiAvailable) {
                return [{
                    kind: "hint",
                    title: "Base de emojis indisponível",
                    subtitle: "Arquivo de dados não encontrado",
                    icon: "󰞅"
                }]
            }

            const values = modes.emojiItems.slice(0, 24)

            if (values.length === 0) {
                return [{
                    kind: "hint",
                    title: "Nenhum emoji",
                    subtitle: "Tente outro termo (ex: fogo, joinha, coração, rindo)",
                    icon: "󰞅"
                }]
            }

            return values.map(item => ({
                kind: "emoji",
                title: item.char + "  " + (item.name ?? item.description ?? ""),
                subtitle: "Inserir emoji · ↵ selecionar",
                icon: item.char,
                emoji: item.char
            }))
        }

        if (trimmed.startsWith("!")) {
            return searchController.searchCloseWindows(trimmed.slice(1), modes.windowItems)
        }

        if (trimmed.startsWith("~")) {
            return searchController.searchWindows(trimmed.slice(1), modes.windowItems)
        }

        if (trimmed.startsWith("=")) {
            return search.calcResult(trimmed.slice(1))
        }

        if (trimmed.startsWith(">")) {
            return searchController.searchShell(trimmed.slice(1))
        }

        return searchController.searchUniversal(trimmed, [...DesktopEntries.applications.values],
                                                root.appUsage, modes.windowItems)
    }

    function deleteCurrentClipboardItem() {
        if (!root.clipboardMode)
            return

        const item = root.selectedResult
        if (!item || item.kind !== "clipboard" || item.clipId === undefined || item.clipId === null)
            return

        clipboard.removeItem(String(item.clipId), String(item.clipSignature ?? ""))

        if (resultList.currentIndex >= root.results.length) {
            resultList.currentIndex = Math.max(0, root.results.length - 1)
        }
    }

    function closeLauncher() {
        root.visible = false
        root.actionPanelOpen = false
        root.actionIndex = 0
        searchInput.text = ""
        resultList.currentIndex = 0
    }

    function openLauncher() {
        root.openRequestedAt = Date.now()
        root.visible = true
        searchInput.text = ""
        resultList.currentIndex = 0
        modes.refreshWindows()
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
        })
    }

    function toggleLauncher() {
        if (root.visible)
            closeLauncher()
        else
            openLauncher()
    }

    // Scroll the selection into view on the next tick, after delegates
    // applied their (possibly expanded) heights. Direct calls race layout
    // and leave tall rows half-hidden.
    function settleSelection() {
        Qt.callLater(function() {
            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain)
        })
    }

    function openWithPrefix(prefix) {
        root.openRequestedAt = Date.now()
        root.visible = true
        const text = prefix.endsWith(" ") ? prefix : (prefix + " ")
        searchInput.text = text
        resultList.currentIndex = 0

        if (prefix.trim() === ";")
            modes.searchEmoji(prefix.endsWith(" ") ? prefix : (prefix + " "))
        else if (prefix.trim() === "!" || prefix.trim() === "~")
            modes.refreshWindows()
        else if (prefix.trim() === "#")
            clipboard.refresh()

        Qt.callLater(function() {
            searchInput.forceActiveFocus()
            searchInput.cursorPosition = searchInput.text.length
        })
    }

    // Etapa 1 Raycast: executa a ação secundária do catálogo sem fechar
    // o launcher (salvo fechar janela). Retorna true se executou.
    function runSecondary(item, actionId) {
        const wanted = String(actionId ?? "")
        const action = wanted.length > 0
            ? actionRegistry.actionsFor(item).find(function(a) { return String(a.id ?? "") === wanted })
            : actionRegistry.secondaryAction(item)
        if (!action)
            return false
        const kind = String(item?.kind ?? "")
        if (action.id === "copy-path" && item.path) {
            Quickshell.execDetached(["wl-copy", String(item.path)])
            return true
        }
        if (action.id === "copy-command") {
            const cmd = String(item.command ?? item.entry?.execString ?? "")
            if (cmd.length > 0) {
                Quickshell.execDetached(["wl-copy", cmd])
                return true
            }
            return false
        }
        if (action.id === "copy-result" && item.value !== undefined) {
            Quickshell.execDetached(["wl-copy", String(item.value ?? "")])
            return true
        }
        if (action.id === "copy" && kind === "clipboard") {
            clipboard.stayOpenOnce = true
            clipboard.restore(String(item.clipId ?? ""), String(item.clipSignature ?? ""))
            return true
        }
        if (action.id === "copy" && kind === "emoji" && item.emoji) {
            Quickshell.execDetached([
                Quickshell.shellDir + "/scripts/launcher-emoji-copy.sh",
                String(item.emoji)
            ])
            return true
        }
        if (action.id === "close" && kind === "window") {
            if (item.handle && typeof item.handle.close === "function") {
                closeLauncher()
                item.handle.close()
                return true
            }
            if (item.address) {
                closeLauncher()
                Quickshell.execDetached([
                    Quickshell.shellDir + "/scripts/compositor-dispatch.sh",
                    "close-window",
                    String(item.address)
                ])
                return true
            }
            return false
        }
        return false
    }

    // Etapa 2 Raycast: executa uma ação do catálogo pelo id. Primárias
    // delegam ao activate() existente (caminho compatível); só as demais
    // executam aqui. Retorna true se executou.
    function runActionById(actionId, item) {
        const id = String(actionId ?? "")
        const kind = String(item?.kind ?? "")
        const actions = actionRegistry.actionsFor(item)
        const spec = actions.find(function(a) { return String(a.id ?? "") === id })
        if (!spec)
            return false
        if (spec.primary || id === "activate") {
            const idx = root.results.indexOf(item)
            root.activate(idx >= 0 ? idx : root.selectedIndex)
            return true
        }
        if (id === "open-new" && item.entry && typeof item.entry.execute === "function") {
            closeLauncher()
            item.entry.execute()
            return true
        }
        if (id === "reveal" && item.path) {
            const dir = String(item.path).split("/").slice(0, -1).join("/") || "/"
            closeLauncher()
            Quickshell.execDetached(["xdg-open", dir])
            return true
        }
        if (id === "terminal") {
            const dir = item.path
                ? String(item.path).split("/").slice(0, -1).join("/") || "/"
                : (Quickshell.env("HOME") ?? "/")
            closeLauncher()
            Quickshell.execDetached(["kitty", "--directory=" + dir])
            return true
        }
        if (id === "focus" && kind === "window") {
            const idx = root.results.indexOf(item)
            if (idx < 0)
                return false
            closeLauncher()
            if (item.handle && typeof item.handle.activate === "function") {
                item.handle.activate()
                return true
            }
            if (item.address) {
                Quickshell.execDetached([
                    Quickshell.shellDir + "/scripts/compositor-dispatch.sh",
                    "window",
                    String(item.address),
                    String(item.workspaceName ?? item.workspaceId ?? "")
                ])
                return true
            }
            return false
        }
        if (id === "delete" && kind === "clipboard") {
            clipboard.removeItem(String(item.clipId ?? ""), String(item.clipSignature ?? ""))
            return true
        }
        // Demais secundárias reutilizam o executor da Etapa 1,
        // com o id explícito (secondaryAction() retornaria só a primeira).
        return runSecondary(item, id)
    }

    function activate(index) {
        if (index < 0 || index >= results.length)
            return

        const item = results[index]

        if (item.kind === "app" && item.entry) {
            const appName = String(item.title ?? item.entry.name ?? "")
            closeLauncher()
            usageBumpProc.command = [
                "python3",
                Quickshell.shellDir + "/scripts/launcher-data.py",
                "bump",
                appName
            ]
            if (!usageBumpProc.running)
                usageBumpProc.running = true

            item.entry.execute()
            return
        }

        if (item.kind === "file" && item.path) {
            const path = item.path
            closeLauncher()
            Quickshell.execDetached(["xdg-open", path])
            return
        }

        if (item.kind === "clipboard" && item.clipId !== undefined && item.clipId !== null && String(item.clipId).length > 0) {
            clipboard.restore(String(item.clipId), String(item.clipSignature ?? ""))
            return
        }

        if (item.kind === "emoji" && item.emoji) {
            const value = item.emoji
            closeLauncher()
            Quickshell.execDetached([
                Quickshell.shellDir + "/scripts/launcher-emoji.sh",
                value
            ])
            return
        }

        if (item.kind === "kill" && item.pid) {
            const pid = String(item.pid)
            closeLauncher()
            Quickshell.execDetached([
                Quickshell.shellDir + "/scripts/launcher-kill.sh",
                pid
            ])
            return
        }

        if (item.kind === "close_window" && item.handle) {
            closeLauncher()
            item.handle.close()
            return
        }

        if (item.kind === "system" && item.command) {
            const command = item.command
            if (String(command[0] ?? "").endsWith("/session-action.sh")) {
                const action = String(command[command.length - 1] ?? "")
                if (["logout", "reboot", "poweroff"].includes(action)) {
                    sessionConfirmation.openConfirmation(action)
                    return
                }
            }
            closeLauncher()
            Quickshell.execDetached(command)
            return
        }

        if (item.kind === "config_category" && item.prefix) {
            searchInput.text = item.prefix
            resultList.currentIndex = 0
            Qt.callLater(function() {
                searchInput.forceActiveFocus()
                searchInput.cursorPosition = searchInput.text.length
            })
            return
        }

        if (item.kind === "settings_open") {
            closeLauncher()
            Quickshell.execDetached(["quickshell", "ipc", "call", "settings", "open"])
            return
        }

        if (item.kind === "wp_pick") {
            closeLauncher()
            Quickshell.execDetached(["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "pick"])
            return
        }

        if (item.kind === "wp_random") {
            closeLauncher()
            Quickshell.execDetached(["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "random"])
            return
        }

        if (item.kind === "idle_toggle") {
            IdleState.inhibited = !IdleState.inhibited
            return
        }

        if (item.kind === "power_profile" && item.profile) {
            PowerProfileState.setProfile(item.profile)
            closeLauncher()
            return
        }

        if (item.kind === "nightlight_set") {
            NightLightState.setEnabled(Boolean(item.val))
            closeLauncher()
            return
        }

        if (item.kind === "restart_quickshell") {
            closeLauncher()
            Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell"])
            return
        }

        if (item.kind === "app_exec" && item.command) {
            closeLauncher()
            Quickshell.execDetached(item.command)
            return
        }

        if (item.kind === "theme_cycle") {
            closeLauncher()
            ThemeState.nextTheme()
            return
        }

        if (item.kind === "nightlight_toggle") {
            closeLauncher()
            NightLightState.toggle()
            return
        }

        if (item.kind === "theme_select" && item.themeId) {
            closeLauncher()
            ThemeState.setTheme(item.themeId)
            return
        }

        if (item.kind === "command" && item.command.length > 0) {
            const cmd = item.command
            closeLauncher()
            Quickshell.execDetached([
                Quickshell.shellDir + "/scripts/run-launcher-command.sh",
                cmd
            ])
            return
        }

        if (item.kind === "window" && item.handle) {
            closeLauncher()
            item.handle.activate()
            return
        }

        if (item.kind === "window" && item.address) {
            const addr = String(item.address)
            const ws = String(item.workspaceName ?? item.workspaceId ?? "")
            closeLauncher()
            Quickshell.execDetached([
                Quickshell.shellDir + "/scripts/compositor-dispatch.sh",
                "window",
                addr,
                ws
            ])
            return
        }

        if (item.kind === "calc") {
            const val = String(item.value ?? "")
            if (val.length > 0) {
                Quickshell.execDetached(["wl-copy", val])
            }
            closeLauncher()
            return
        }
    }

    Process {
        id: usageLoadProc
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/launcher-data.py",
            "usage"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.appUsage = obj.usage ?? ({})
                } catch (e) {
                    root.appUsage = ({})
                }
            }
        }
    }

    Process {
        id: usageBumpProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.appUsage = obj.usage ?? root.appUsage
                } catch (e) {
                }
            }
        }
    }


    Component.onCompleted: {
        if (!usageLoadProc.running)
            usageLoadProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            resultList.currentIndex = 0

            if (root.openRequestedAt > 0) {
                console.log("Spotlight open latency: "
                    + Math.max(0, Math.round(Date.now() - root.openRequestedAt)) + "ms")
                root.openRequestedAt = 0
            }
            Qt.callLater(function() {
                searchInput.forceActiveFocus()
            })
            focusRetry.attempts = 0
            focusRetry.start()
        } else {
            focusRetry.stop()
        }
    }

    onSelectedResultChanged: {
        root.actionIndex = 0
    }

    // Compositors without GlobalShortcut activation (e.g. labwc, driven via
    // `quickshell ipc call spotlight …`) may map the layer surface before
    // transferring keyboard focus, so a single Qt.callLater request can land
    // while the window is still inactive. Retry briefly until the input
    // actually holds active focus, then stop. No-op on Hyprland, where the
    // first request already succeeds.
    Timer {
        id: focusRetry
        interval: 60
        repeat: true
        property int attempts: 0
        onTriggered: {
            if (!root.visible || searchInput.activeFocus) {
                attempts = 0
                stop()
                return
            }
            if (++attempts > 8) {
                attempts = 0
                stop()
                return
            }
            searchInput.forceActiveFocus()
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight"
        description: "Toggle Quickshell Spotlight launcher"
        onPressed: root.toggleLauncher()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight-emoji"
        description: "Open Spotlight emoji picker"
        onPressed: root.openWithPrefix(";")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight-kill"
        description: "Open Spotlight window killer"
        onPressed: root.openWithPrefix("!")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight-actions"
        description: "Open Spotlight actions"
        onPressed: root.openWithPrefix(":")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight-clipboard"
        description: "Open Spotlight clipboard history"
        onPressed: root.openWithPrefix("#")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "spotlight-windows"
        description: "Open Spotlight window switcher"
        onPressed: root.openWithPrefix("~")
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeLauncher()
        }
    }

    Item {
        id: centerAnchor
        width: (root.clipboardMode || root.themeMode || (root.actionPanelOpen && root.selectedResult !== null)) ? 820 : 560
        height: card.height

        Behavior on width {
            enabled: palette.qmlAnimationsEnabled
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(82, Math.round(parent.height * 0.13))

        Rectangle {
            id: glow
            anchors.fill: card
            anchors.margins: -5
            radius: 24
            color: Qt.rgba(137/255,180/255,250/255,0.038)
            border.width: 1
            border.color: Qt.rgba(137/255,180/255,250/255,0.055)
        }

        Rectangle {
            id: card
            width: parent.width
            height: root.emojiMode
                    ? (80 + Math.max(1, Math.ceil(Math.min(root.results.length, 24) / 8)) * 46 + 34)
                    : root.themeMode ? 600
                    : root.clipboardMode ? 500
                    : (root.actionPanelOpen && root.selectedResult !== null) ? 480
                    : (66
                       + (results.length > 0
                          ? Math.min(results.length, 6) * 49 + 6
                          : 70)
                       + 34)

            Behavior on height {
                enabled: palette.qmlAnimationsEnabled
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            radius: 20
            color: root.launcherBackground
            border.width: 1
            border.color: palette.borderPopup
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                    mouse.accepted = true
                    searchInput.forceActiveFocus()
                }
            }

            Column {
                anchors.fill: parent
                spacing: 0

                Item {
                    width: parent.width
                    height: 58

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 18
                        spacing: 13

                        Item {
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter

                            // Draw the search icon ourselves instead of relying on
                            // a Nerd Font glyph/fallback. This guarantees that the
                            // icon follows the shell palette.
                            Item {
                                anchors.fill: parent
                                visible: !root.commandMode && !root.calcMode && !root.fileMode && !root.clipboardMode && !root.actionMode && !root.emojiMode && !root.killMode && !root.windowMode

                                Rectangle {
                                    width: 13
                                    height: 13
                                    radius: 6.5
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.leftMargin: 2
                                    anchors.topMargin: 2
                                    color: "transparent"
                                    border.width: 2
                                    border.color: root.launcherBlue
                                }

                                Rectangle {
                                    width: 8
                                    height: 2
                                    radius: 1
                                    x: 13
                                    y: 15
                                    rotation: 45
                                    transformOrigin: Item.Left
                                    color: root.launcherBlue
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.commandMode || root.calcMode || root.fileMode || root.clipboardMode || root.actionMode || root.emojiMode || root.killMode || root.windowMode
                                text: root.commandMode ? ""
                                      : (root.calcMode ? "󰪚"
                                         : (root.fileMode ? "󰈔"
                                            : (root.clipboardMode ? "󰅇"
                                               : (root.emojiMode ? "󰞅"
                                                  : (root.killMode ? "󰅖"
                                                     : (root.windowMode ? "󰖯" : "󰐥"))))))
                                color: root.commandMode
                                       ? root.launcherGreen
                                       : (root.calcMode
                                          ? root.launcherPink
                                          : (root.fileMode
                                             ? root.launcherBlue
                                             : (root.clipboardMode
                                                ? root.launcherSecondary
                                                : (root.emojiMode
                                                   ? root.launcherYellow
                                                   : (root.killMode
                                                      ? root.launcherRed
                                                      : (root.windowMode ? root.launcherCyan : root.launcherOrange))))))
                                font.family: palette.nerdFontFamily
                                font.pixelSize: 21
                            }
                        }

                        TextInput {
                            id: searchInput

                            width: parent.width - 165
                            height: parent.height
                            verticalAlignment: TextInput.AlignVCenter

                            color: root.launcherForeground
                            selectionColor: Qt.rgba(137/255,180/255,250/255,0.38)
                            selectedTextColor: palette.foreground

                            font.family: palette.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Medium

                            clip: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Buscar"
                                textFormat: Text.PlainText
                                visible: searchInput.text.length === 0
                                color: root.launcherMuted
                                font.family: palette.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.Medium
                            }

                            onTextChanged: {
                                resultList.currentIndex = 0

                                if (root.fileMode)
                                    modes.searchFiles(root.query)

                                if (root.clipboardMode) {
                                    if (!clipboard.loaded
                                            && !clipboard.snapshotRunning)
                                        clipboard.refresh()
                                    else
                                        clipboard.scheduleThumbnails()
                                }

                                if (root.emojiMode)
                                    modes.searchEmoji(root.query)

                                if (root.killMode || root.windowMode)
                                    modes.refreshWindows()
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_F6 && root.themeMode) {
                                    themePane.kbZone = themePane.kbZone === "catalog" ? "gallery" : "catalog"
                                    event.accepted = true
                                } else if (event.key === Qt.Key_K
                                           && (event.modifiers & Qt.ControlModifier)
                                           && root.selectedResult !== null
                                           && !root.clipboardMode && !root.themeMode) {
                                    root.actionPanelOpen = !root.actionPanelOpen
                                    root.actionIndex = 0
                                    if (root.actionPanelOpen)
                                        root.panelBaseQuery = searchInput.text
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Right
                                           && event.modifiers === Qt.NoModifier
                                           && !root.actionPanelOpen
                                           && root.selectedResult !== null
                                           && !root.clipboardMode && !root.themeMode && !root.emojiMode
                                           && searchInput.cursorPosition === searchInput.text.length
                                           && searchInput.selectedText.length === 0) {
                                    root.actionPanelOpen = true
                                    root.actionIndex = 0
                                    root.panelBaseQuery = searchInput.text
                                    event.accepted = true
                                } else if (root.actionPanelOpen
                                           && event.key === Qt.Key_Left
                                           && event.modifiers === Qt.NoModifier) {
                                    root.actionPanelOpen = false
                                    event.accepted = true
                                } else if (root.actionPanelOpen && event.key === Qt.Key_Escape) {
                                    root.actionPanelOpen = false
                                    event.accepted = true
                                } else if (root.actionPanelOpen
                                           && (event.key === Qt.Key_Down || event.key === Qt.Key_Up)) {
                                    const n = actionRegistry.actionsFor(root.selectedResult).length
                                    if (n > 0) {
                                        const d = event.key === Qt.Key_Down ? 1 : -1
                                        const cur = root.actionIndex >= 0 && root.actionIndex < n ? root.actionIndex : 0
                                        root.actionIndex = (cur + d + n) % n
                                    }
                                    event.accepted = true
                                } else if (root.actionPanelOpen
                                           && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                    const acts = actionRegistry.actionsFor(root.selectedResult)
                                    const spec = acts[root.actionIndex] ?? acts[0]
                                    if (spec && root.runActionById(spec.id, root.selectedResult)) {
                                        root.actionPanelOpen = false
                                        event.accepted = true
                                    }
                                } else if (root.emojiMode && (event.key === Qt.Key_Down || event.key === Qt.Key_Up)) {
                                    if (root.results.length > 0) {
                                        const len = root.results.length
                                        const cur = Math.min(Math.max(0, root.emojiIndex), len - 1)
                                        const d = event.key === Qt.Key_Down ? 1 : -1
                                        root.emojiIndex = (cur + d + len) % len
                                    }
                                    event.accepted = true
                                } else if (root.themeMode && (event.key === Qt.Key_Right || event.key === Qt.Key_Left)) {
                                    themePane.wpMove(event.key === Qt.Key_Right ? 1 : -1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (root.themeMode) {
                                        themePane.wpMove(1)
                                    } else if (root.results.length > 0) {
                                        resultList.currentIndex =
                                            (resultList.currentIndex + 1) % root.results.length
                                        root.settleSelection()
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    if (root.themeMode) {
                                        themePane.wpMove(-1)
                                    } else if (root.results.length > 0) {
                                        resultList.currentIndex =
                                            (resultList.currentIndex - 1 + root.results.length)
                                            % root.results.length
                                        root.settleSelection()
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageDown) {
                                    if (root.results.length > 0) {
                                        resultList.currentIndex =
                                            Math.min(root.results.length - 1, resultList.currentIndex + 6)
                                        root.settleSelection()
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageUp) {
                                    if (root.results.length > 0) {
                                        resultList.currentIndex =
                                            Math.max(0, resultList.currentIndex - 6)
                                        root.settleSelection()
                                    }
                                    event.accepted = true
                                } else if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Back)
                                           && (event.modifiers & Qt.ShiftModifier)) {
                                    if (root.clipboardMode) {
                                        root.deleteCurrentClipboardItem()
                                        event.accepted = true
                                    }
                                } else if (event.key === Qt.Key_Delete
                                           && root.clipboardMode
                                           && searchInput.cursorPosition >= searchInput.text.length
                                           && searchInput.selectedText.length === 0) {
                                    root.deleteCurrentClipboardItem()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return
                                           && (event.modifiers & Qt.ControlModifier)) {
                                    if (root.runSecondary(root.selectedResult)) {
                                        event.accepted = true
                                    }
                                } else if (event.key === Qt.Key_Return
                                           || event.key === Qt.Key_Enter) {
                                    if (root.emojiMode && root.results.length > 0) {
                                        root.emojiIndex = Math.min(Math.max(0, root.emojiIndex), root.results.length - 1)
                                        root.activate(root.emojiIndex)
                                        event.accepted = true
                                    } else if (root.themeMode) {
                                        let done = themePane.kbZone === "catalog"
                                            ? themePane.catActivateSelected()
                                            : themePane.wpActivateSelected()
                                        if (!done)
                                            root.activate(resultList.currentIndex)
                                        event.accepted = true
                                    } else {
                                        root.activate(resultList.currentIndex)
                                        event.accepted = true
                                    }
                                } else if (
                                    event.key === Qt.Key_C
                                    && (event.modifiers & Qt.ControlModifier)
                                    && root.calcMode
                                ) {                                    const value = searchInput.selectedText.length > 0
                                                  ? searchInput.selectedText
                                                  : searchInput.text.replace(/^=/, "").trim()

                                    if (value.length > 0)
                                        Quickshell.execDetached(["wl-copy", value])

                                    event.accepted = true
                                } else if (event.key === Qt.Key_Backspace
                                           && (searchInput.text === ":tema "
                                               || searchInput.text === ":luz "
                                               || searchInput.text === ":energia "
                                               || searchInput.text === ":conexoes "
                                               || searchInput.text === ":sistema "
                                               || searchInput.text === ":sessao ")) {
                                    searchInput.text = ": "
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    root.closeLauncher()
                                    event.accepted = true
                                }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: modeText.implicitWidth + 10
                            height: 20
                            radius: 6

                            color: "transparent"
                            border.width: 0

                            Text {
                                id: modeText
                                anchors.centerIn: parent
                                text: root.commandMode
                                      ? "Comando"
                                      : (root.calcMode
                                         ? "Cálculo"
                                         : (root.fileMode
                                            ? "Arquivos"
                                            : (root.clipboardMode
                                               ? "Clipboard"
                                               : (root.actionMode
                                                  ? getActionModeTitle(root.query)
                                                  : (root.emojiMode
                                                     ? "Emoji"
                                                     : (root.killMode ? "Kill" : (root.windowMode ? "Janelas" : (root.query.trim().length > 0 ? "Tudo" : "Apps"))))))))
                                color: root.launcherMuted
                                font.family: palette.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            id: powerQuickBtn
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            radius: 8

                            color: powerHover.hovered
                                   ? Qt.rgba(root.launcherOrange.r, root.launcherOrange.g, root.launcherOrange.b, 0.22)
                                   : (root.actionMode ? Qt.rgba(root.launcherOrange.r, root.launcherOrange.g, root.launcherOrange.b, 0.15) : palette.pillBackground)
                            border.width: 1
                            border.color: powerHover.hovered || root.actionMode
                                          ? Qt.rgba(root.launcherOrange.r, root.launcherOrange.g, root.launcherOrange.b, 0.45)
                                          : palette.pillBorder

                            HoverHandler {
                                id: powerHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    if (root.actionMode) {
                                        searchInput.text = ""
                                    } else {
                                        root.openWithPrefix(":")
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒓"
                                font.family: palette.nerdFontFamily
                                font.pixelSize: 13
                                color: powerHover.hovered || root.actionMode ? root.launcherOrange : root.launcherSecondary
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 28
                    height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(88/255,91/255,112/255,0.38)
                }

                Item {
                    id: contentArea
                    width: parent.width
                    height: card.height - 107

                    // LEFT PANE: List of results (hidden in theme mode;
                    // keyboard nav still works through the model)
                    Item {
                        id: listContainer
                        visible: !root.themeMode
                        width: (root.clipboardMode || (root.actionPanelOpen && root.selectedResult !== null)) ? 380 : (root.themeMode ? 0 : parent.width)
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        Text {
                            anchors.centerIn: parent
                            visible: root.results.length === 0
                            text: "Nenhum resultado"
                            color: root.launcherSecondary
                            opacity: 0.72
                            font.family: palette.fontFamily
                            font.pixelSize: 12
                        }

                        ListView {
                            id: resultList
                            visible: !root.emojiMode || root.results.length === 0 || root.results[0].kind !== "emoji"

                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: (root.clipboardMode || root.themeMode || (root.actionPanelOpen && root.selectedResult !== null)) ? 4 : 8
                            anchors.topMargin: 7
                            anchors.bottomMargin: 2

                            model: root.results
                            currentIndex: 0

                            WheelKinetic { target: resultList }

                            clip: true
                            spacing: 2
                            keyNavigationWraps: true
                            interactive: contentHeight > height

                            highlightMoveDuration: 90
                            highlightResizeDuration: 90

                            highlight: Rectangle {
                                radius: 12
                                color: palette.cardBackgroundHover
                                border.width: 1
                                border.color: palette.borderRegular
                            }

                            delegate: LauncherItemDelegate {
                                palette: palette
                                showProvider: !root.fileMode && !root.clipboardMode
                                              && !root.actionMode && !root.commandMode
                                              && !root.calcMode && !root.emojiMode
                                              && !root.killMode && !root.windowMode
                                              && root.query.trim().length > 0
                                currentIndex: resultList.currentIndex
                                launcherForeground: root.launcherForeground
                                launcherSecondary: root.launcherSecondary
                                launcherMuted: root.launcherMuted
                                launcherPink: root.launcherPink
                                launcherGreen: root.launcherGreen
                                launcherCyan: root.launcherCyan
                                launcherRed: root.launcherRed
                                launcherBlue: root.launcherBlue

                                onActivated: function(idx) {
                                    if (root.clipboardMode) {
                                        if (resultList.currentIndex === idx) {
                                            root.activate(idx)
                                        } else {
                                            resultList.currentIndex = idx
                                        }
                                    } else {
                                        resultList.currentIndex = idx
                                        // Keep the newly expanded row fully visible.
                                        root.settleSelection()
                                        root.activate(idx)
                                    }
                                }
                            }
                        }

                        // Raycast-style emoji grid (emojiMode only).
                        Flow {
                            id: emojiGrid
                            visible: root.emojiMode && root.results.length > 0 && root.results[0].kind === "emoji"
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            anchors.topMargin: 10
                            anchors.bottomMargin: 6
                            spacing: 6

                            Repeater {
                                model: root.results

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: (emojiGrid.width - 42) / 8
                                    height: 40
                                    radius: 10
                                    color: index === root.emojiIndex
                                           ? palette.cardBackgroundHover
                                           : (emojiHov.hovered ? palette.cardBackgroundHover : "transparent")
                                    border.width: index === root.emojiIndex ? 1 : 0
                                    border.color: palette.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.emoji ?? ""
                                        font.pixelSize: 24
                                    }

                                    MouseArea {
                                        id: emojiHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onContainsMouseChanged: {
                                            if (containsMouse)
                                                root.emojiIndex = index
                                        }
                                        onClicked: {
                                            root.emojiIndex = index
                                            root.activate(index)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // DIVIDER: Visible in clipboard mode & action panel mode
                    Rectangle {
                        id: clipboardDivider
                        visible: root.clipboardMode || (root.actionPanelOpen && root.selectedResult !== null && !root.themeMode)
                        width: 1
                        anchors.left: root.themeMode ? parent.left : listContainer.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        color: Qt.rgba(88/255,91/255,112/255,0.38)
                    }

                    // RIGHT PANE: Live Preview (Raycast/Alfred style)
                    ClipboardPreview {
                        id: previewPane
                        visible: root.clipboardMode
                        anchors.left: clipboardDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        palette: palette
                        result: root.selectedResult
                        store: clipboard
                        active: root.clipboardMode
                        onDeleteRequested: root.deleteCurrentClipboardItem()
                        onPasteRequested: {
                            if (resultList.currentIndex >= 0)
                                root.activate(resultList.currentIndex)
                        }
                    }

                    // RIGHT PANE: Live Theme & Wallpaper Preview (Material You)
                    ThemePreviewPane {
                        id: themePane
                        visible: root.themeMode
                        anchors.left: clipboardDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        palette: palette
                        selectedItem: root.selectedResult
                        active: root.themeMode
                        filterText: root.query
                        onFolderPickerRequested: root.visible = false
                        onFolderPickerFinished: {
                            root.visible = true
                            searchInput.forceActiveFocus()
                        }
                        onWallpaperSelectionRequested: searchInput.forceActiveFocus()
                    }

                    // RIGHT PANE: Detalhes & Ações Contextuais (Raycast Detail & Actions, Ctrl+K)
                    SpotlightActionPanel {
                        id: actionPanel
                        visible: root.actionPanelOpen && root.selectedResult !== null && !root.clipboardMode && !root.themeMode
                        anchors.left: clipboardDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        palette: palette
                        actions: actionRegistry.actionsFor(root.selectedResult)
                        currentIndex: root.actionIndex
                        targetItem: root.selectedResult
                        filterText: {
                            const base = root.panelBaseQuery
                            const q = searchInput.text
                            return (base.length > 0 && q.startsWith(base)) ? q.slice(base.length) : ""
                        }
                        onActionChosen: function(actionId) {
                            root.runActionById(actionId, root.selectedResult)
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 28
                    height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(88/255,91/255,112/255,0.38)
                }

                SpotlightActionBar {
                    id: actionBar
                    visible: root.actionBarVisible
                    palette: palette
                    primaryText: root.actionBarPrimary
                    secondaryText: root.actionBarSecondary
                    onPrimaryClicked: root.activate(root.selectedIndex)
                    onSecondaryClicked: root.runSecondary(root.selectedResult)
                }

                LauncherChips {
                    visible: !root.actionBarVisible
                    palette: palette
                    launcherForeground: root.launcherForeground
                    launcherMuted: root.launcherMuted
                    launcherBlue: root.launcherBlue
                    launcherSecondary: root.launcherSecondary
                    launcherCyan: root.launcherCyan
                    launcherOrange: root.launcherOrange
                    launcherYellow: root.launcherYellow
                    launcherRed: root.launcherRed
                    launcherGreen: root.launcherGreen
                    launcherPink: root.launcherPink
                    fileMode: root.fileMode
                    clipboardMode: root.clipboardMode
                    windowMode: root.windowMode
                    actionMode: root.actionMode
                    emojiMode: root.emojiMode
                    killMode: root.killMode
                    commandMode: root.commandMode
                    calcMode: root.calcMode

                    onChipClicked: function(prefix, isActive) {
                        if (isActive) {
                            searchInput.text = ""
                        } else {
                            root.openWithPrefix(prefix)
                        }
                    }
                }
            }
        }
    }
}
