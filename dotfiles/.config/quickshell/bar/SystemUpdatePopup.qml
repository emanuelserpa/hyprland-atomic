import QtQuick
import Quickshell
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target

    property var repoData: ({})
    property var aurData: ({})
    property var flatpakData: ({})
    property var brewData: ({})
    property bool showPackages: false

    signal refreshRequested()
    signal updateRequested(string backend)

    readonly property int repoCount: Number(repoData?.count ?? 0)
    readonly property int aurCount: Number(aurData?.count ?? 0)
    readonly property int flatpakCount: Number(flatpakData?.count ?? 0)
    readonly property int brewCount: Number(brewData?.count ?? 0)
    readonly property int totalCount: repoCount + aurCount + flatpakCount + brewCount

    readonly property var packageRows: {
        const rows = []
        const append = (label, accent, data) => {
            const items = data?.items ?? []
            for (let i = 0; i < items.length; i++) {
                rows.push({
                    "backend": label,
                    "accent": accent,
                    "text": String(items[i] ?? "")
                })
            }
        }
        append("Repo", theme.blue, repoData)
        append("AUR", theme.pink, aurData)
        append("Flatpak", theme.cyan, flatpakData)
        append("Brew", theme.orange, brewData)
        return rows
    }

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 7

    implicitWidth: 326
    implicitHeight: showPackages ? 468 : 318

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
        }
    }

    function statusText(data, count) {
        const status = String(data?.status ?? "")
        if (status === "timeout") return "timeout"
        if (status === "error") return "erro"
        if (count === 0) return "ok"
        return String(count)
    }

    function statusColor(data, count, accent) {
        const status = String(data?.status ?? "")
        if (status === "timeout") return theme.yellow
        if (status === "error") return theme.red
        if (count === 0) return theme.green
        return accent
    }

    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent

        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            Row {
                width: parent.width
                height: 30
                spacing: 6

                Text {
                    width: parent.width - refreshButton.width - 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Atualizações"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Rectangle {
                    id: refreshButton
                    width: 30
                    height: 26
                    radius: 7
                    color: refreshHover.hovered
                           ? Qt.rgba(69/255,71/255,90/255,0.55)
                           : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(69/255,71/255,90/255,0.55)

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: root.theme.cyan
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 13
                    }

                    HoverHandler { id: refreshHover }
                    TapHandler { onTapped: root.refreshRequested() }
                }
            }

            Text {
                width: parent.width
                text: root.totalCount === 0
                      ? "Tudo atualizado"
                      : root.totalCount + " atualizações disponíveis"
                color: root.totalCount === 0
                       ? root.theme.green
                       : root.theme.offWhite
                font.family: root.theme.fontFamily
                font.pixelSize: 11
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(88/255,91/255,112/255,0.38)
            }

            Column {
                width: parent.width
                spacing: 4

                UpdateBackendRow {
                    width: parent.width
                    theme: root.theme
                    icon: "󰣇"
                    title: "Repositórios"
                    subtitle: "pacman / repos oficiais"
                    accentColor: root.theme.blue
                    statusText: root.statusText(root.repoData, root.repoCount)
                    statusColor: root.statusColor(root.repoData, root.repoCount, root.theme.blue)
                    onRunRequested: root.updateRequested("repo")
                }

                UpdateBackendRow {
                    width: parent.width
                    theme: root.theme
                    icon: "󰏗"
                    title: "AUR"
                    subtitle: String(root.aurData?.status ?? "") === "timeout"
                              ? "consulta expirou — pode tentar de novo"
                              : "isolado dos repositórios"
                    accentColor: root.theme.pink
                    statusText: root.statusText(root.aurData, root.aurCount)
                    statusColor: root.statusColor(root.aurData, root.aurCount, root.theme.pink)
                    onRunRequested: root.updateRequested("aur")
                }

                UpdateBackendRow {
                    width: parent.width
                    theme: root.theme
                    icon: ""
                    title: "Flatpak"
                    subtitle: "apps e runtimes"
                    accentColor: root.theme.cyan
                    statusText: root.statusText(root.flatpakData, root.flatpakCount)
                    statusColor: root.statusColor(root.flatpakData, root.flatpakCount, root.theme.cyan)
                    onRunRequested: root.updateRequested("flatpak")
                }

                UpdateBackendRow {
                    width: parent.width
                    theme: root.theme
                    icon: ""
                    title: "Homebrew"
                    subtitle: "brew packages"
                    accentColor: root.theme.orange
                    statusText: root.statusText(root.brewData, root.brewCount)
                    statusColor: root.statusColor(root.brewData, root.brewCount, root.theme.orange)
                    onRunRequested: root.updateRequested("brew")
                }
            }

            Row {
                width: parent.width
                height: 30
                spacing: 7

                Rectangle {
                    width: (parent.width - 7) * 0.42
                    height: parent.height
                    radius: 7
                    color: packagesHover.hovered
                           ? root.theme.cardBackgroundHover
                           : root.theme.cardBackgroundSubtle
                    border.width: 1
                    border.color: packagesHover.hovered
                                  ? root.theme.borderRegular
                                  : root.theme.borderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: root.showPackages ? "Ocultar" : "Ver pacotes"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    HoverHandler { id: packagesHover }
                    TapHandler { onTapped: root.showPackages = !root.showPackages }
                }

                Rectangle {
                    width: parent.width - ((parent.width - 7) * 0.42) - 7
                    height: parent.height
                    radius: 7
                    color: updateAllHover.hovered
                           ? Qt.rgba(137/255,180/255,250/255,0.26)
                           : Qt.rgba(137/255,180/255,250/255,0.14)
                    border.width: 1
                    border.color: Qt.rgba(137/255,180/255,250/255,0.55)

                    Text {
                        anchors.centerIn: parent
                        text: "Atualizar tudo"
                        color: root.theme.blue
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }

                    HoverHandler { id: updateAllHover }
                    TapHandler { onTapped: root.updateRequested("all") }
                }
            }

            Item {
                width: parent.width
                height: root.showPackages ? 143 : 0
                visible: root.showPackages

                Text {
                    anchors.centerIn: parent
                    visible: root.packageRows.length === 0
                    text: "Nenhum pacote pendente."
                    color: root.theme.grey
                    font.family: root.theme.fontFamily
                    font.pixelSize: 10
                }

                ListView {
                    id: packageList
                    anchors.fill: parent
                    visible: root.packageRows.length > 0
                    model: root.packageRows
                    spacing: 3
                    clip: true

                    WheelKinetic { target: packageList }

                    delegate: Row {
                        required property var modelData
                        width: ListView.view.width
                        height: 25
                        spacing: 6

                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: modelData.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            width: 50
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.backend
                            color: modelData.accent
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width - 60
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            color: root.theme.offWhite
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
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
