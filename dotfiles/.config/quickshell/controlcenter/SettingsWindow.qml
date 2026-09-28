pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.components
import qs.services

FloatingWindow {
    id: root

    required property var theme

    title: "Configurações"
    implicitWidth: 800
    implicitHeight: 560
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false

    property string currentTab: "wallpaper"
    property string activeWallpaper: ThemeState.palette?.wallpaper ?? ""
    property bool isWorking: false
    property string statusMessage: ""

    IpcHandler {
        target: "settings"

        function toggle() { root.visible = !root.visible }
        function open() { root.visible = true }
        function close() { root.visible = false }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    Process {
        id: wpProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.isWorking = false
                try {
                    const res = JSON.parse(this.text.trim())
                    if (res && res.ok) {
                        if (res.wallpaper) {
                            root.activeWallpaper = res.wallpaper
                        }
                        root.statusMessage = "Papel de parede atualizado!"
                        statusTimer.restart()
                    } else if (res && res.error) {
                        root.statusMessage = res.error
                        statusTimer.restart()
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 3500
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    function runWallpaperAction(action, arg) {
        if (root.isWorking) return
        root.isWorking = true
        root.statusMessage = "Processando..."
        const cmd = ["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", action]
        if (arg && String(arg).length > 0) cmd.push(String(arg))
        wpProc.command = cmd
        wpProc.running = true
    }

    Rectangle {
        id: windowCard
        anchors.fill: parent
        radius: root.theme.radiusPopup
        color: root.theme.background
        border.width: 1
        border.color: root.theme.borderPopup

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ==========================================
            // HEADER BAR
            // ==========================================
            Row {
                width: parent.width
                height: 38
                spacing: 12

                Text {
                    width: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒓"
                    color: root.theme.accent
                    font.family: root.theme.nerdFontFamily
                    font.pixelSize: 20
                }

                Column {
                    width: parent.width - 24 - 12 - 32 - 12 - 32
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Configurações"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.statusMessage.length > 0 ? root.statusMessage : "Personalização visual e preferências do desktop shell"
                        color: root.statusMessage.length > 0 ? root.theme.accent : root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Botão Voltar ao Spotlight
                Rectangle {
                    width: 32
                    height: 32
                    radius: root.theme.radiusSm
                    anchors.verticalCenter: parent.verticalCenter
                    color: spotHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: spotHover.hovered ? root.theme.borderRegular : root.theme.borderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "󰍉"
                        color: spotHover.hovered ? root.theme.accent : root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: spotHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            root.visible = false
                            Quickshell.execDetached(["quickshell", "ipc", "call", "spotlight", "toggle"])
                        }
                    }
                }

                // Botão Fechar
                Rectangle {
                    width: 32
                    height: 32
                    radius: root.theme.radiusSm
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: closeHover.hovered ? root.theme.borderRegular : root.theme.borderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeHover.hovered ? root.theme.red : root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: root.visible = false }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.borderSubtle
            }

            // ==========================================
            // CORPO PRINCIPAL (SIDEBAR + CONTEÚDO)
            // ==========================================
            Row {
                width: parent.width
                height: parent.height - 52
                spacing: 14

                // --- SIDEBAR DE NAVEGAÇÃO ---
                Column {
                    width: 190
                    height: parent.height
                    spacing: 6

                    // Botão 1: Wallpaper & Cores
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: root.theme.radiusMd
                        color: root.currentTab === "wallpaper" ? root.theme.primaryContainer : (navWpHover.hovered ? root.theme.cardBackgroundHover : "transparent")
                        border.width: 1
                        border.color: root.currentTab === "wallpaper" ? root.theme.primary : (navWpHover.hovered ? root.theme.borderRegular : "transparent")

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                color: root.currentTab === "wallpaper" ? root.theme.primary : root.theme.offWhite
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Wallpaper & Cores"
                                color: root.currentTab === "wallpaper" ? root.theme.foreground : root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 12
                                font.weight: root.currentTab === "wallpaper" ? Font.Bold : Font.Normal
                            }
                        }

                        HoverHandler { id: navWpHover }
                        TapHandler { onTapped: root.currentTab = "wallpaper" }
                    }

                    // Botão 2: Barra & Layout
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: root.theme.radiusMd
                        color: root.currentTab === "bar" ? root.theme.primaryContainer : (navBarHover.hovered ? root.theme.cardBackgroundHover : "transparent")
                        border.width: 1
                        border.color: root.currentTab === "bar" ? root.theme.primary : (navBarHover.hovered ? root.theme.borderRegular : "transparent")

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰄯"
                                color: root.currentTab === "bar" ? root.theme.primary : root.theme.offWhite
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Barra & Layout"
                                color: root.currentTab === "bar" ? root.theme.foreground : root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 12
                                font.weight: root.currentTab === "bar" ? Font.Bold : Font.Normal
                            }
                        }

                        HoverHandler { id: navBarHover }
                        TapHandler { onTapped: root.currentTab = "bar" }
                    }

                    // Botão 3: Adaptadores & Sistema
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: root.theme.radiusMd
                        color: root.currentTab === "system" ? root.theme.primaryContainer : (navSysHover.hovered ? root.theme.cardBackgroundHover : "transparent")
                        border.width: 1
                        border.color: root.currentTab === "system" ? root.theme.primary : (navSysHover.hovered ? root.theme.borderRegular : "transparent")

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰒓"
                                color: root.currentTab === "system" ? root.theme.primary : root.theme.offWhite
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Adaptadores & Sistema"
                                color: root.currentTab === "system" ? root.theme.foreground : root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 12
                                font.weight: root.currentTab === "system" ? Font.Bold : Font.Normal
                            }
                        }

                        HoverHandler { id: navSysHover }
                        TapHandler { onTapped: root.currentTab = "system" }
                    }
                }

                // Divisor vertical
                Rectangle {
                    width: 1
                    height: parent.height
                    color: root.theme.borderSubtle
                }

                // --- PAINEL DE CONTEÚDO ---
                Item {
                    width: parent.width - 190 - 1 - 14
                    height: parent.height

                    // TAB 1: WALLPAPER & CORES
                    Flickable {
                        id: wpFlickable
                        anchors.fill: parent
                        visible: root.currentTab === "wallpaper"
                        contentWidth: width
                        contentHeight: wpCol.implicitHeight + 20
                        clip: true

                        WheelKinetic { target: wpFlickable }

                        Column {
                            id: wpCol
                            width: parent.width
                            spacing: 14

                            // CARD: WALLPAPER ATUAL & AÇÕES
                            Rectangle {
                                width: parent.width
                                height: 160
                                radius: root.theme.radiusLg
                                color: root.theme.cardBackground
                                border.width: 1
                                border.color: root.theme.borderRegular

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 16

                                    // Thumbnail do Wallpaper
                                    Rectangle {
                                        width: 230
                                        height: 136
                                        radius: root.theme.radiusMd
                                        clip: true
                                        color: root.theme.surface

                                        Image {
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            source: root.activeWallpaper ? ("file://" + root.activeWallpaper) : ("file://" + Quickshell.env("HOME") + "/.cache/current_wallpaper")
                                            cache: false
                                            asynchronous: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: root.theme.radiusMd
                                            color: "transparent"
                                            border.width: 1
                                            border.color: root.theme.glassBorder
                                        }
                                    }

                                    // Ações do Wallpaper
                                    Column {
                                        width: parent.width - 230 - 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            text: "Papel de Parede Ativo"
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideMiddle
                                            text: root.activeWallpaper ? root.activeWallpaper.split("/").pop() : "current_wallpaper"
                                            color: root.theme.grey
                                            font.family: root.theme.monoFontFamily
                                            font.pixelSize: 10
                                        }

                                        Row {
                                            spacing: 8

                                            // Botão: Escolher Arquivo
                                            Rectangle {
                                                width: 125
                                                height: 32
                                                radius: root.theme.radiusSm
                                                color: pickHover.hovered ? root.theme.cardBackgroundHover : root.theme.primaryContainer
                                                border.width: 1
                                                border.color: root.theme.primary

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "󰈔"
                                                        color: root.theme.primary
                                                        font.family: root.theme.nerdFontFamily
                                                        font.pixelSize: 13
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Escolher..."
                                                        color: root.theme.foreground
                                                        font.family: root.theme.fontFamily
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                    }
                                                }

                                                HoverHandler { id: pickHover }
                                                TapHandler { onTapped: root.runWallpaperAction("pick") }
                                            }

                                            // Botão: Aleatório
                                            Rectangle {
                                                width: 100
                                                height: 32
                                                radius: root.theme.radiusSm
                                                color: randHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                                                border.width: 1
                                                border.color: root.theme.borderSubtle

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: ""
                                                        color: root.theme.offWhite
                                                        font.family: root.theme.nerdFontFamily
                                                        font.pixelSize: 13
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Aleatório"
                                                        color: root.theme.offWhite
                                                        font.family: root.theme.fontFamily
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                HoverHandler { id: randHover }
                                                TapHandler { onTapped: root.runWallpaperAction("random") }
                                            }

                                            // Botão: Recarregar Paleta
                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: root.theme.radiusSm
                                                color: syncHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                                                border.width: 1
                                                border.color: root.theme.borderSubtle

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰔎"
                                                    color: root.theme.accent
                                                    font.family: root.theme.nerdFontFamily
                                                    font.pixelSize: 14
                                                }

                                                HoverHandler { id: syncHover }
                                                TapHandler { onTapped: Quickshell.execDetached(["python3", "-B", Quickshell.shellDir + "/scripts/theme-manager.py", "update-wallpaper"]) }
                                            }
                                        }
                                    }
                                }
                            }

                            // SEÇÃO: MODO CLARO / ESCURO
                            Column {
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: "Aparência Geral"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                Row {
                                    spacing: 8

                                    // Botão Escuro
                                    Rectangle {
                                        width: 120
                                        height: 34
                                        radius: root.theme.radiusSm
                                        color: !root.theme.isLight ? root.theme.primaryContainer : root.theme.cardBackgroundSubtle
                                        border.width: 1
                                        border.color: !root.theme.isLight ? root.theme.primary : root.theme.borderSubtle

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰖔"
                                                color: !root.theme.isLight ? root.theme.primary : root.theme.offWhite
                                                font.family: root.theme.nerdFontFamily
                                                font.pixelSize: 14
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Escuro"
                                                color: !root.theme.isLight ? root.theme.foreground : root.theme.offWhite
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: !root.theme.isLight ? Font.Bold : Font.Normal
                                            }
                                        }

                                        HoverHandler { id: darkHover }
                                        TapHandler { onTapped: ThemeState.setTheme("chameleon") }
                                    }

                                    // Botão Claro
                                    Rectangle {
                                        width: 120
                                        height: 34
                                        radius: root.theme.radiusSm
                                        color: root.theme.isLight ? root.theme.primaryContainer : root.theme.cardBackgroundSubtle
                                        border.width: 1
                                        border.color: root.theme.isLight ? root.theme.primary : root.theme.borderSubtle

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰖙"
                                                color: root.theme.isLight ? root.theme.primary : root.theme.offWhite
                                                font.family: root.theme.nerdFontFamily
                                                font.pixelSize: 14
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Claro"
                                                color: root.theme.isLight ? root.theme.foreground : root.theme.offWhite
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: root.theme.isLight ? Font.Bold : Font.Normal
                                            }
                                        }

                                        HoverHandler { id: lightHover }
                                        TapHandler { onTapped: ThemeState.setTheme("chameleon-light") }
                                    }
                                }
                            }

                            // Três aparências baseadas na mesma paleta Material.
                            Column {
                                width: parent.width
                                spacing: 8
                                Text {
                                    text: "Chameleon (Material You)"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 8
                                    Repeater {
                                        model: [
                                            { id: "chameleon", label: "Normal" },
                                            { id: "chameleon-light", label: "Claro" },
                                            { id: "chameleon-oled", label: "OLED" }
                                        ]
                                        Rectangle {
                                            required property var modelData
                                            readonly property bool selected: ThemeState.currentTheme === modelData.id
                                            width: 130
                                            height: 34
                                            radius: root.theme.radiusSm
                                            activeFocusOnTab: true
                                            color: selected ? root.theme.primaryContainer : (chipHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle)
                                            border.width: 1
                                            border.color: selected ? root.theme.primary : root.theme.borderSubtle
                                            Keys.onReturnPressed: ThemeState.setTheme(modelData.id)
                                            Keys.onEnterPressed: ThemeState.setTheme(modelData.id)
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Rectangle {
                                                    width: 8
                                                    height: 8
                                                    radius: 4
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: ThemeState.palettes[modelData.id]?.accent ?? root.theme.accent
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.label
                                                    color: selected ? root.theme.foreground : root.theme.offWhite
                                                    font.family: root.theme.fontFamily
                                                    font.pixelSize: 11
                                                    font.weight: selected ? Font.Bold : Font.Normal
                                                }
                                            }
                                            HoverHandler { id: chipHover }
                                            TapHandler { onTapped: ThemeState.setTheme(modelData.id) }
                                        }
                                    }
                                }
                            }

                            // SEÇÃO: CATÁLOGO DE TEMAS ESTÁTICOS
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Temas Clássicos"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { id: "catppuccin-mocha", label: "Catppuccin Mocha", color: "#89b4fa" },
                                            { id: "tokyo-night", label: "Tokyo Night", color: "#7aa2f7" },
                                            { id: "nord", label: "Nord", color: "#88c0d0" },
                                            { id: "dracula", label: "Dracula", color: "#bd93f9" },
                                            { id: "everforest", label: "Everforest", color: "#a7c080" },
                                            { id: "gruvbox", label: "Gruvbox", color: "#fe8019" },
                                            { id: "rose-pine", label: "Rosé Pine", color: "#c4a7e7" },
                                            { id: "solarized-dark", label: "Solarized Dark", color: "#268bd2" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 125
                                            height: 28
                                            radius: root.theme.radiusSm
                                            color: ThemeState.currentTheme === modelData.id ? root.theme.primaryContainer : (tHover.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle)
                                            border.width: 1
                                            border.color: ThemeState.currentTheme === modelData.id ? root.theme.primary : root.theme.borderSubtle

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Rectangle {
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: modelData.color
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.label
                                                    color: ThemeState.currentTheme === modelData.id ? root.theme.foreground : root.theme.offWhite
                                                    font.family: root.theme.fontFamily
                                                    font.pixelSize: 10
                                                }
                                            }

                                            HoverHandler { id: tHover }
                                            TapHandler { onTapped: ThemeState.setTheme(modelData.id) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // TAB 2: BARRA & LAYOUT
                    Column {
                        anchors.fill: parent
                        visible: root.currentTab === "bar"
                        spacing: 14

                        Text {
                            text: "Barra Superior & Disposição"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            width: parent.width
                            height: 110
                            radius: root.theme.radiusLg
                            color: root.theme.cardBackground
                            border.width: 1
                            border.color: root.theme.borderSubtle

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Text {
                                    text: "Posição da Barra"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }

                                Row {
                                    spacing: 8

                                    Rectangle {
                                        width: 100
                                        height: 32
                                        radius: root.theme.radiusSm
                                        color: root.theme.primaryContainer
                                        border.width: 1
                                        border.color: root.theme.primary

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰁝 Superior"
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Rectangle {
                                        width: 100
                                        height: 32
                                        radius: root.theme.radiusSm
                                        color: root.theme.cardBackgroundSubtle
                                        border.width: 1
                                        border.color: root.theme.borderSubtle

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰁅 Inferior"
                                            color: root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                Text {
                                    text: "Posição ativa: Topo com altura de 37px e margem de 3px"
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 130
                            radius: root.theme.radiusLg
                            color: root.theme.cardBackground
                            border.width: 1
                            border.color: root.theme.borderSubtle

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Text {
                                    text: "Estilo Visual da Barra"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }

                                Row {
                                    spacing: 8

                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: root.theme.radiusSm
                                        color: root.theme.primaryContainer
                                        border.width: 1
                                        border.color: root.theme.primary

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰖲 Flutuante (Float)"
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: root.theme.radiusSm
                                        color: root.theme.cardBackgroundSubtle
                                        border.width: 1
                                        border.color: root.theme.borderSubtle

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄯 Total (Hug)"
                                            color: root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                Text {
                                    text: "O estilo Flutuante mantém cantos arredondados (radius 9px) e borda de vidro sutil."
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }

                    // TAB 3: ADAPTADORES & SISTEMA
                    Column {
                        anchors.fill: parent
                        visible: root.currentTab === "system"
                        spacing: 14

                        Text {
                            text: "Sincronização de Adaptadores"
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Quando você altera um tema ou wallpaper, os adaptadores abaixo são sincronizados:"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                        }

                        Flow {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    { name: "Quickshell", key: "quickshell", icon: "󰄯" },
                                    { name: "Ghostty", key: "ghostty", icon: "󰞷" },
                                    { name: "Hyprland", key: "hyprland", icon: "󰣇" },
                                    { name: "Hyprlock", key: "hyprlock", icon: "󰌾" },
                                    { name: "BTOP", key: "btop", icon: "󰄬" },
                                    { name: "Qt / Kvantum", key: "qt", icon: "󰟀" },
                                    { name: "GTK", key: "gtk", icon: "󰕰" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isSynced: Boolean(ThemeState.syncedAdapters[modelData.key])
                                    width: 160
                                    height: 48
                                    radius: root.theme.radiusMd
                                    color: root.theme.cardBackground
                                    border.width: 1
                                    border.color: isSynced ? root.theme.green : root.theme.borderSubtle

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.icon
                                            color: isSynced ? root.theme.green : root.theme.grey
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 16
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                text: modelData.name
                                                color: root.theme.foreground
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                            }

                                            Text {
                                                text: isSynced ? "Sincronizado" : "Pendente / Inativo"
                                                color: isSynced ? root.theme.green : root.theme.grey
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 220
                            height: 36
                            radius: root.theme.radiusSm
                            color: syncAllHov.hovered ? root.theme.cardBackgroundHover : root.theme.cardBackgroundSubtle
                            border.width: 1
                            border.color: root.theme.borderRegular

                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰑐"
                                    color: root.theme.accent
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 14
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Forçar Ressincronização"
                                    color: root.theme.foreground
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            HoverHandler { id: syncAllHov }
                            TapHandler {
                                onTapped: {
                                    ThemeState.refresh()
                                    root.statusMessage = "Ressincronizando adaptadores..."
                                    statusTimer.restart()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
