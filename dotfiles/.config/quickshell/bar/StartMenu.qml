import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components

// Traditional menu popup: categories on the left, apps of the selected
// category on the right. Search stays in Spotlight; this is browsing.
PopupWindow {
    id: root

    required property var theme
    required property Item target

    implicitWidth: 540
    implicitHeight: 400
    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 6

    onVisibleChanged: {
        if (visible) {
            selectedCat = "all"
            card.forceActiveFocus()
        }
    }

    property string selectedCat: "all"

    readonly property var categories: [
        { id: "all", label: "Todos", icon: "󰕱", match: [] },
        { id: "media", label: "Multimídia", icon: "", match: ["AudioVideo", "Audio", "Video", "Player", "Recorder"] },
        { id: "dev", label: "Desenvolvimento", icon: "󰘐", match: ["Development"] },
        { id: "edu", label: "Educação", icon: "", match: ["Education"] },
        { id: "game", label: "Jogos", icon: "󰊴", match: ["Game"] },
        { id: "graphics", label: "Gráficos", icon: "", match: ["Graphics"] },
        { id: "net", label: "Rede", icon: "󰤨", match: ["Network"] },
        { id: "office", label: "Escritório", icon: "", match: ["Office"] },
        { id: "system", label: "Sistema", icon: "󰒓", match: ["System", "Settings", "Administration"] },
        { id: "science", label: "Ciência", icon: "", match: ["Science"] },
        { id: "util", label: "Utilitários", icon: "", match: ["Utility"] },
        { id: "other", label: "Outros", icon: "", match: [] }
    ]

    function entryCats(entry) {
        // entry.categories shape varies (JS Array, QML list or ";"-joined
        // string): indexed access covers Array and QML list, split covers
        // the string form. Anything else yields no categories.
        try {
            const c = entry.categories
            if (!c) return []
            if (Array.isArray(c)) return c.map(function(x) { return String(x) })
            if (typeof c === "string") {
                return String(c).split(";").map(function(x) { return String(x).trim() })
                                .filter(function(x) { return x.length > 0 })
            }
            if (typeof c.length === "number") {
                const out = []
                for (let i = 0; i < c.length; i++) out.push(String(c[i]))
                return out
            }
            return []
        } catch (e) {
            return []
        }
    }

    function bucketOf(entry) {
        const cats = root.entryCats(entry)
        for (let i = 1; i < root.categories.length - 1; i++) {
            const bucket = root.categories[i]
            for (let j = 0; j < bucket.match.length; j++) {
                if (cats.indexOf(bucket.match[j]) !== -1) return bucket.id
            }
        }
        return "other"
    }

    function hasIcon(entry) {
        // Entries without a resolvable theme icon render as a bare dot
        // and are usually plugin stubs (e.g. zam* JACK helpers). Fail open
        // so a lookup hiccup never empties the menu.
        try {
            const src = Quickshell.iconPath(String(entry?.icon ?? ""), true)
            return String(src ?? "").length > 0
        } catch (e) {
            return true
        }
    }

    readonly property var allApps: {
        const out = []
        try {
            for (const entry of [...DesktopEntries.applications.values]) {
                if (!entry || !entry.name || entry.noDisplay) continue
                if (!root.hasIcon(entry)) continue
                out.push(entry)
            }
        } catch (e) {}
        out.sort(function(a, b) { return String(a.name).localeCompare(String(b.name)) })
        return out
    }

    function appsIn(bucketId) {
        if (bucketId === "all") return root.allApps
        return root.allApps.filter(function(e) { return root.bucketOf(e) === bucketId })
    }

    function countIn(bucketId) {
        if (bucketId === "all") return root.allApps.length
        return root.appsIn(bucketId).length
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        cardClip: true

        Keys.onEscapePressed: root.visible = false

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Categories
            Flickable {
                id: catFlick
                width: 150
                height: parent.height
                contentWidth: width
                contentHeight: catList.implicitHeight
                clip: true

                WheelKinetic { target: catFlick }

                Column {
                    id: catList
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.categories

                        delegate: Rectangle {
                            required property var modelData
                            visible: root.countIn(modelData.id) > 0 || modelData.id === "all"
                            width: catList.width
                            height: visible ? 32 : 0
                            radius: 8
                            color: root.selectedCat === modelData.id
                                   ? Qt.rgba(137/255, 180/255, 250/255, 0.20)
                                   : catHover.hovered
                                     ? Qt.rgba(69/255, 71/255, 90/255, 0.45)
                                     : "transparent"
                            border.width: root.selectedCat === modelData.id ? 1 : 0
                            border.color: Qt.rgba(137/255, 180/255, 250/255, 0.35)

                            Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                spacing: 8

                                Text {
                                    text: modelData.icon
                                    color: root.selectedCat === modelData.id ? root.theme.blue : root.theme.grey
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 52
                                    text: modelData.label
                                    color: root.selectedCat === modelData.id ? root.theme.foreground : root.theme.offWhite
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: root.selectedCat === modelData.id ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: String(root.countIn(modelData.id))
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler { id: catHover }
                            TapHandler {
                                onTapped: root.selectedCat = modelData.id
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: Qt.rgba(88/255, 91/255, 112/255, 0.35)
            }

            // Apps of the selected category
            Flickable {
                id: appFlick
                width: parent.width - catFlick.width - 11
                height: parent.height
                contentWidth: width
                contentHeight: appList.implicitHeight
                clip: true

                WheelKinetic { target: appFlick }

                Column {
                    id: appList
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.appsIn(root.selectedCat)

                        delegate: Rectangle {
                            required property var modelData
                            width: appList.width
                            height: 40
                            radius: 8
                            color: appHover.hovered
                                   ? Qt.rgba(69/255, 71/255, 90/255, 0.45)
                                   : "transparent"

                            Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                spacing: 9

                                Text {
                                    visible: !appIcon.visible
                                    text: ""
                                    color: root.theme.blue
                                    font.family: root.theme.nerdFontFamily
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                IconImage {
                                    id: appIcon
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: source.toString().length > 0
                                    source: Quickshell.iconPath(String(modelData.icon ?? ""), true)
                                }

                                Column {
                                    width: parent.width - 42
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        width: parent.width
                                        text: String(modelData.name ?? "")
                                        color: root.theme.foreground
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: String(modelData.genericName ?? modelData.comment ?? "")
                                        visible: text.length > 0
                                        color: root.theme.grey
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            HoverHandler { id: appHover }
                            TapHandler {
                                onTapped: {
                                    root.visible = false
                                    try {
                                        modelData.execute()
                                    } catch (e) {}
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
