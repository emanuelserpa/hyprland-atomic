pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Item {
    id: root

    signal folderPickerRequested()
    signal folderPickerFinished()
    signal wallpaperSelectionRequested()

    required property var palette
    property var selectedItem: null
    property bool active: false
    property string filterText: ""
    property string kbZone: "gallery"
    property int catIndex: -1

    function catEntries() {
        const q = String(root.filterText ?? "").replace(/^:\w*\s*/, "").trim().toLowerCase()
        return (ThemeState.themesList ?? []).filter(function(t) {
            return q.length === 0 || String(t.name ?? "").toLowerCase().includes(q)
        })
    }

    function catMove(dx, dy) {
        const items = root.catEntries()
        if (items.length === 0)
            return
        const cols = 3
        let idx = root.catIndex
        if (idx < 0 || idx >= items.length) {
            const cur = items.findIndex(function(t) { return t.id === ThemeState.currentTheme })
            idx = cur >= 0 ? cur : 0
        } else {
            const row = Math.floor(idx / cols) + dy
            const col = Math.min(cols - 1, Math.max(0, (idx % cols) + dx))
            idx = row * cols + col
        }
        root.catIndex = Math.min(items.length - 1, Math.max(0, idx))
        root.kbZone = "catalog"
        root.catEnsureVisible()
    }

    function catEnsureVisible() {
        if (root.catIndex < 0)
            return
        const rowH = 26 + 6
        const y = Math.floor(root.catIndex / 3) * rowH
        if (y < themesFlick.contentY)
            themesFlick.contentY = y
        else if (y + rowH > themesFlick.contentY + themesFlick.height)
            themesFlick.contentY = Math.min(y + rowH - themesFlick.height, themesFlick.contentHeight - themesFlick.height)
    }

    function catActivateSelected() {
        const items = root.catEntries()
        const item = items[root.catIndex]
        if (item && item.id) {
            ThemeState.setTheme(item.id)
            return true
        }
        return false
    }

    onFilterTextChanged: {
        root.catIndex = -1
        if (root.kbZone === "catalog")
            root.kbZone = "gallery"
    }
    property var wpItems: []
    property int wpIndex: -1

    readonly property var activeWallpaperItem: (root.wpItems ?? []).find(function(w) { return w.current }) ?? null
    readonly property var galleryItems: (root.wpItems ?? []).filter(function(w) { return !w.current })

    function wpSyncIndex() {
        const items = root.galleryItems ?? []
        root.wpIndex = items.length > 0 ? 0 : -1
    }

    function wpMove(d) {
        const items = root.galleryItems
        if (items.length === 0)
            return
        let idx = root.wpIndex
        if (idx < 0 || idx >= items.length)
            idx = 0
        root.wpIndex = (idx + d + items.length) % items.length
        root.kbZone = "gallery"
        root.wpEnsureVisible()
    }

    function wpEnsureVisible() {
        if (root.wpIndex < 0)
            return
        thumbFlick.positionViewAtIndex(root.wpIndex, ListView.Contain)
    }

    function wpActivateSelected() {
        const items = root.galleryItems
        const item = items[root.wpIndex]
        if (item && !item.current) {
            root.applyWallpaper(item.path)
            return true
        }
        return false
    }

    onWpItemsChanged: root.wpSyncIndex()

    Process {
        id: wpListProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(this.text.trim())
                    if (res && res.ok && Array.isArray(res.items))
                        root.wpItems = res.items
                } catch (e) {}
            }
        }
    }

    Process {
        id: wpApplyProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshGallery()
            }
        }
    }

    Process {
        id: wpFolderProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.folderPickerFinished()
                root.refreshGallery()
            }
        }
    }

    Timer {
        id: folderPickerDelay
        interval: 150
        repeat: false
        onTriggered: {
            wpFolderProc.command = ["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "folder"]
            wpFolderProc.running = true
        }
    }

    Process {
        id: wpRandomProc
        stdout: StdioCollector {
            onStreamFinished: root.refreshGallery()
        }
    }

    function refreshGallery() {
        if (wpListProc.running)
            return
        wpListProc.command = ["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "list"]
        wpListProc.running = true
    }

    function applyWallpaper(path) {
        if (wpApplyProc.running)
            return
        wpApplyProc.command = ["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "apply", String(path)]
        wpApplyProc.running = true
    }

    onActiveChanged: {
        if (active)
            Qt.callLater(root.refreshGallery)
    }

    readonly property color cForeground: root.palette.foreground
    readonly property color cSecondary: root.palette.offWhite
    readonly property color cMuted: root.palette.grey
    readonly property color cAccent: root.palette.accent
    readonly property color cCardBg: root.palette.cardBackground
    readonly property color cCardHover: root.palette.cardBackgroundHover
    readonly property color cBorder: root.palette.borderSubtle

    readonly property string currentWallpaper: ThemeState.palette?.wallpaper ?? (Quickshell.env("HOME") + "/.cache/current_wallpaper")
    readonly property string wallpaperName: currentWallpaper ? currentWallpaper.split("/").pop() : "current_wallpaper"
    readonly property string wallpaperSource: {
        if (!currentWallpaper) return ""
        if (currentWallpaper.startsWith("file://")) return currentWallpaper
        return "file://" + encodeURI(currentWallpaper)
    }

    visible: root.active

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 10

        // Fluxo único: galeria / tema / cores / temas
        Column {
            width: parent.width
            spacing: 10

            // TÍTULO
            // Top: Título do Tema Ativo + Badges de Sincronização
            Item {
            width: parent.width
            height: 24

            Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
            width: 20
            height: 20
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.22)
            border.width: 1
            border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.45)

            Text {
            anchors.centerIn: parent
            text: "󰔎"
            color: root.cAccent
            font.family: root.palette.nerdFontFamily
            font.pixelSize: 11
            }
            }

            Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ThemeState.palette?.name ?? ThemeState.currentTheme
            color: root.cForeground
            font.family: root.palette.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            }

            Rectangle {
            height: 16
            width: activeTagText.implicitWidth + 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(root.palette.green.r, root.palette.green.g, root.palette.green.b, 0.18)
            border.width: 1
            border.color: root.palette.green

            Text {
            id: activeTagText
            anchors.centerIn: parent
            text: "Ativo"
            color: root.palette.green
            font.family: root.palette.fontFamily
            font.pixelSize: 8
            font.weight: Font.Bold
            }
            }
            }

            // Status resumido dos adaptadores
            Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: {
            const ad = ThemeState.syncedAdapters ?? {}
            const g = ad.ghostty ? "Ghostty ✓" : "Ghostty –"
            const h = ad.hyprland ? "Hyprland ✓" : "Hyprland –"
            return g + " · " + h
            }
            color: root.cMuted
            font.family: root.palette.fontFamily
            font.pixelSize: 9
            }
            }

            // Wallpaper ativo em destaque; o restante fica na faixa navegável.
            Row {
                width: parent.width
                height: 190
                spacing: 10

                Rectangle {
                    id: activeWallpaperCard
                    width: Math.min(338, parent.width * 0.43)
                    height: parent.height
                    radius: 8
                    clip: true
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.cAccent

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 676
                        sourceSize.height: 380
                        source: root.activeWallpaperItem?.path
                                ? ("file://" + encodeURI(String(root.activeWallpaperItem.path)))
                                : root.wallpaperSource
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 34
                        color: root.palette.backgroundOpaque
                        opacity: 0.88
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Ativo"
                            color: root.cAccent
                            font.family: root.palette.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                        Text {
                            width: parent.width - 45
                            text: root.activeWallpaperItem?.filename ?? root.wallpaperName
                            elide: Text.ElideMiddle
                            color: root.cForeground
                            font.family: root.palette.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Column {
                    width: parent.width - activeWallpaperCard.width - 10
                    height: parent.height
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 20
                        spacing: 6

                        Text {
                            id: galleryLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Galeria · " + root.wpItems.length
                            color: root.cSecondary
                            font.family: root.palette.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Item { width: Math.max(0, parent.width - galleryLabel.implicitWidth - folderButton.width - randomButton.width - 18); height: 1 }

                        Rectangle {
                            id: folderButton
                            width: folderText.implicitWidth + 12
                            height: 20
                            radius: 5
                            color: folderHov.hovered ? root.cCardHover : root.palette.cardBackgroundSubtle
                            border.width: 1
                            border.color: root.cBorder
                            Text {
                                id: folderText
                                anchors.centerIn: parent
                                text: "Escolher pasta"
                                color: root.cSecondary
                                font.family: root.palette.fontFamily
                                font.pixelSize: 9
                            }
                            HoverHandler { id: folderHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (!wpFolderProc.running && !folderPickerDelay.running) {
                                        root.folderPickerRequested()
                                        folderPickerDelay.start()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: randomButton
                            width: 24
                            height: 20
                            radius: 5
                            color: randHov.hovered ? root.cCardHover : root.palette.cardBackgroundSubtle
                            border.width: 1
                            border.color: root.cBorder
                            Text {
                                anchors.centerIn: parent
                                text: "\u21BB"
                                color: root.cAccent
                                font.pixelSize: 11
                            }
                            HoverHandler { id: randHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (!wpRandomProc.running) {
                                        wpRandomProc.command = ["python3", "-B", Quickshell.shellDir + "/scripts/wallpaper-action.py", "random"]
                                        wpRandomProc.running = true
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: thumbFlick
                        width: parent.width
                        height: 132
                        clip: true
                        orientation: ListView.Horizontal
                        spacing: 6
                        model: root.galleryItems
                        cacheBuffer: 290
                        boundsBehavior: Flickable.StopAtBounds

                        WheelKinetic {
                            id: galleryWheel
                            target: thumbFlick
                            orientation: Qt.Horizontal
                            enabled: false
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 218
                            height: 123
                            radius: 6
                            clip: true
                            color: root.palette.surface
                            border.width: 1
                            border.color: root.cBorder

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 436
                                sourceSize.height: 246
                                source: modelData.path ? ("file://" + encodeURI(String(modelData.path))) : ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: index === root.wpIndex ? 3 : 0
                                border.color: root.cAccent
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onWheel: function(wheel) { galleryWheel.handle(wheel) }
                                onClicked: {
                                    root.wpIndex = index
                                    root.wallpaperSelectionRequested()
                                }
                                onDoubleClicked: {
                                    root.wpIndex = index
                                    root.wpActivateSelected()
                                }
                            }
                        }
                    }

                    Text {
                        text: root.galleryItems.length > 0 ? "Clique ou ← → para selecionar · Enter/duplo clique aplica" : "Nenhum outro wallpaper nesta pasta"
                        color: root.cMuted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 9
                    }
                }
            }

        }


        // Amostras de cor da paleta ativa
        Row {
            width: parent.width
            height: 16
            spacing: 5

            Repeater {
                model: [
                    root.palette.accent,
                    root.palette.surfaceElevated,
                    root.palette.surfaceHover,
                    root.palette.red,
                    root.palette.green,
                    root.palette.yellow,
                    root.palette.blue,
                    root.palette.pink,
                    root.palette.cyan,
                    root.palette.orange
                ]

                delegate: Rectangle {
                    required property color modelData
                    width: (parent.width - 45) / 10
                    height: 16
                    radius: 4
                    color: modelData
                    border.width: 1
                    border.color: root.palette.glassBorderSubtle
                }
            }
        }
        // Divisor sutil
        Rectangle {
            width: parent.width
            height: 1
            color: root.palette.glassBorderSubtle
        }

        // =====================================================================
        // PARTE INFERIOR: CATÁLOGO DE TEMAS (COM SCROLL INTERNO SEGURO)
        // =====================================================================
        Column {
            width: parent.width
            spacing: 6

            Row {
                width: parent.width
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Catálogo de Temas"
                    color: root.cForeground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "· digite para filtrar, clique ou F6 + setas/Enter"
                    color: root.cMuted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 9
                }
            }

            // Flickable para garantir ZERO transbordamento / overflow no rodapé
            Flickable {
                id: themesFlick
                width: parent.width
                height: Math.min(165, themesFlow.implicitHeight)
                contentWidth: width
                contentHeight: themesFlow.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WheelKinetic { target: themesFlick }

                Flow {
                    id: themesFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.catEntries()

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isSelected: ThemeState.currentTheme === modelData.id
                            readonly property bool kbCursor: root.kbZone === "catalog" && index === root.catIndex
                            width: (themesFlow.width - 12) / 3
                            height: 26
                            radius: root.palette.radiusSm
                            color: isSelected ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.22) : (kbCursor || thHov.hovered ? root.cCardHover : root.palette.cardBackgroundSubtle)
                            border.width: kbCursor ? 2 : 1
                            border.color: (isSelected || kbCursor) ? root.cAccent : root.cBorder

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.accent ?? root.cAccent
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: isSelected ? root.cForeground : root.cSecondary
                                    font.family: root.palette.fontFamily
                                    font.pixelSize: 9
                                    font.weight: isSelected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }

                            HoverHandler { id: thHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: ThemeState.setTheme(modelData.id) }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                onContainsMouseChanged: {
                                    if (containsMouse)
                                        root.catIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
