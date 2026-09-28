import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Etapa 5 do fatiamento do Spotlight: fontes de busca por modo
// (arquivos `@`, emojis `;`, janelas `~`/`!`). Cada seção é dona do seu
// processo, estado e debounce. O Spotlight continua dono dos atalhos,
// do ciclo de vida da janela, dos prefixos de modo e da exibição.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    // ---- Arquivos (@) ----
    property var fileItems: []
    property string pendingFileQuery: ""

    function searchFiles(query) {
        root.pendingFileQuery = String(query ?? "")
        fileSearchDelay.restart()
    }

    Process {
        id: fileSearchProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.fileItems = obj.items ?? []
                } catch (e) {
                    root.fileItems = []
                }
            }
        }
    }

    Timer {
        id: fileSearchDelay
        interval: 120
        repeat: false

        onTriggered: {
            const value = root.pendingFileQuery.trim()
            if (!value.startsWith("@"))
                return

            const q = value.slice(1).trim()
            if (q.length < 2) {
                root.fileItems = []
                return
            }

            if (fileSearchProc.running)
                fileSearchProc.running = false

            fileSearchProc.command = [
                "python3",
                Quickshell.shellDir + "/scripts/launcher-data.py",
                "files",
                q
            ]
            fileSearchProc.running = true
        }
    }

    // ---- Emojis (;) ----
    property var emojiItems: []
    property bool emojiAvailable: true
    property string pendingEmojiQuery: ""

    function searchEmoji(query) {
        root.pendingEmojiQuery = String(query ?? "")
        emojiSearchDelay.restart()
    }

    Process {
        id: emojiProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.emojiAvailable = obj.available !== false
                    root.emojiItems = obj.items ?? []
                } catch (e) {
                    root.emojiItems = []
                }
            }
        }
    }

    Timer {
        id: emojiSearchDelay
        interval: 90
        repeat: false

        onTriggered: {
            const value = root.pendingEmojiQuery.trim()
            if (!value.startsWith(";"))
                return

            const q = value.slice(1).trim()

            if (emojiProc.running)
                emojiProc.running = false

            emojiProc.command = [
                "python3",
                Quickshell.shellDir + "/scripts/launcher-data.py",
                "emoji",
                q
            ]
            emojiProc.running = true
        }
    }

    // ---- Janelas (~/!) ----
    property var windowItems: []
    readonly property bool hyprlandActive:
        (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase().split(":").includes("hyprland")

    function refreshWindows() {
        if (!root.hyprlandActive) {
            root.windowItems = ToplevelManager.toplevels.values.map(function(window) {
                return {
                    title: window.title || window.appId || "Janela",
                    class: window.appId || "Aplicativo",
                    handle: window,
                    workspaceName: ""
                }
            })
            return
        }
        windowRefreshDelay.restart()
    }

    Process {
        id: windowsProc
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/launcher-data.py",
            "windows"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.windowItems = obj.items ?? []
                } catch (e) {
                    root.windowItems = []
                }
            }
        }
    }

    Timer {
        id: windowRefreshDelay
        interval: 60
        repeat: false
        onTriggered: {
            if (!windowsProc.running)
                windowsProc.running = true
        }
    }
}
