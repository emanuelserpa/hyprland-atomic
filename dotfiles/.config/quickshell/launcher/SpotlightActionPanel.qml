pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

// Painel de Detalhes & Ações do Spotlight inspirado no Raycast (Detail & Actions)
// Exibido na coluna direita quando Ctrl+K é acionado, integrando metadados e ações.
Item {
    id: root

    required property var palette
    property var actions: []
    property int currentIndex: 0
    property var targetItem: null
    signal actionChosen(string actionId)

    // Filtro digitado com o painel aberto + agrupamento por seção.
    property string filterText: ""
    readonly property var groupOrder: ["Principal", "Copiar", "Ações", "Gerenciar"]
    readonly property var panelEntries: {
        const q = String(root.filterText ?? "").trim().toLowerCase()
        const out = []
        for (let gi = 0; gi < root.groupOrder.length; gi++) {
            const g = root.groupOrder[gi]
            const items = (root.actions ?? []).filter(function(a) {
                return String(a.group ?? "Ações") === g
                    && (q.length === 0
                        || String(a.title ?? "").toLowerCase().includes(q)
                        || String(a.id ?? "").toLowerCase().includes(q))
            })
            if (items.length === 0)
                continue
            for (let i = 0; i < items.length; i++)
                out.push({ action: items[i] })
        }
        return out
    }

    function entryActionAt(idx) {
        const e = root.panelEntries[idx]
        return e && e.action ? e.action : null
    }

    function panelMove(d) {
        const entries = root.panelEntries
        if (entries.length === 0)
            return
        let idx = root.currentIndex
        if (idx < 0 || idx >= entries.length)
            idx = 0
        for (let step = 0; step < entries.length; step++) {
            idx = (idx + d + entries.length) % entries.length
            if (entries[idx].action)
                break
        }
        root.currentIndex = idx
    }

    function panelActivate() {
        const a = root.entryActionAt(root.currentIndex)
            ?? root.entryActionAt(root.panelEntries.findIndex(function(e) { return e.action }))
        if (a && a.id) {
            root.actionChosen(a.id)
            return true
        }
        return false
    }

    readonly property string kind: String(root.targetItem?.kind ?? "")

    readonly property string kindLabel: {
        switch (root.kind) {
        case "app": return "Aplicativo"
        case "file": return "Arquivo"
        case "window": return "Janela"
        case "clipboard": return "Área de Transferência"
        case "calc": return "Cálculo"
        case "command": return "Comando"
        case "theme_select": return "Tema"
        default: return "Item"
        }
    }

    readonly property string iconGlyph: {
        switch (root.kind) {
        case "window": return "󰖯"
        case "file": return "󰈔"
        case "command": return "󰆍"
        case "calc": return "󰃬"
        case "clipboard": return "󰅍"
        case "theme_select": return "󰔎"
        default: return "󰌌"
        }
    }

    readonly property string detailSecondary: {
        if (!root.targetItem) return ""
        if (root.targetItem.usageCount && root.targetItem.usageCount > 0)
            return "Usado " + root.targetItem.usageCount + " vezes no launcher"
        if (root.targetItem.workspaceName || root.targetItem.workspaceId)
            return "Workspace: " + (root.targetItem.workspaceName ?? root.targetItem.workspaceId)
        return ""
    }

    Column {
        anchors.fill: parent
        spacing: 12

        // =====================================================================
        // HEADER: Ícone grande + Nome do item + Badge de Categoria + Subtítulo
        // =====================================================================
        Row {
            width: parent.width
            height: 48
            spacing: 12

            // Container do Ícone (44x44)
            Rectangle {
                width: 44
                height: 44
                radius: 12
                color: root.palette.cardBackgroundSubtle
                border.width: 1
                border.color: root.palette.borderSubtle
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                IconImage {
                    id: headerAppIcon
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    visible: (root.kind === "app" || root.kind === "window")
                             && String(root.targetItem?.icon ?? "").length > 0
                    source: visible ? Quickshell.iconPath(root.targetItem.icon, true) : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !headerAppIcon.visible
                    text: root.iconGlyph
                    color: root.palette.accent
                    font.family: root.palette.nerdFontFamily
                    font.pixelSize: 22
                }
            }

            // Textos do Topo
            Column {
                width: parent.width - 56
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: String(root.targetItem?.title ?? "")
                        color: root.palette.foreground
                        font.family: root.palette.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(implicitWidth, parent.width - categoryBadge.width - 8)
                    }

                    Rectangle {
                        id: categoryBadge
                        height: 18
                        width: catText.implicitWidth + 10
                        radius: 5
                        color: Qt.rgba(root.palette.accent.r, root.palette.accent.g, root.palette.accent.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(root.palette.accent.r, root.palette.accent.g, root.palette.accent.b, 0.35)
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: root.kindLabel
                            color: root.palette.accent
                            font.family: root.palette.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: String(root.targetItem?.subtitle ?? "")
                    color: root.palette.grey
                    font.family: root.palette.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text.length > 0
                }
            }
        }

        // =====================================================================
        // CARD DE METADADOS: só uso/workspace (sem IDs internos nem comandos crus;
        // o comando continua disponível em "Copiar comando")
        // =====================================================================
        Rectangle {
            width: parent.width
            height: metaCol.implicitHeight + 16
            radius: 10
            color: root.palette.cardBackgroundSubtle
            border.width: 1
            border.color: root.palette.borderSubtle
            visible: root.detailSecondary.length > 0

            Column {
                id: metaCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Linha única: uso / workspace
                Row {
                    width: parent.width
                    spacing: 6
                    visible: root.detailSecondary.length > 0

                    Text {
                        text: "󰄲"
                        color: root.palette.green
                        font.family: root.palette.nerdFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 20
                        text: root.detailSecondary
                        color: root.palette.grey
                        font.family: root.palette.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // =====================================================================
        // SEPARADOR & RÓTULO DA SEÇÃO DE AÇÕES
        // =====================================================================
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "AÇÕES DISPONÍVEIS"
                color: root.palette.grey
                font.family: root.palette.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width - 130
                height: 1
                color: root.palette.borderSubtle
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // =====================================================================
        // LISTA DE AÇÕES (REFINADA: SEM WIREFRAME, COM ÍCONES E KEYCAPS)
        // =====================================================================
        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.panelEntries

                delegate: Rectangle {
                    id: actionRow
                    required property var modelData
                    required property int index

                    readonly property var action: modelData.action ?? modelData

                    readonly property bool isSelected: index === root.currentIndex
                    readonly property string actionIcon: String(action.icon ?? "󰌌")
                    readonly property string actionHint: String(action.hint ?? "")

                    width: parent.width
                    height: 36
                    radius: 8
                    color: isSelected
                           ? Qt.rgba(root.palette.accent.r, root.palette.accent.g, root.palette.accent.b, 0.18)
                           : (rowHov.hovered ? root.palette.cardBackgroundHover : "transparent")
                    border.width: isSelected ? 1 : 0
                    border.color: Qt.rgba(root.palette.accent.r, root.palette.accent.g, root.palette.accent.b, 0.45)

                    // Indicador vertical sutil à esquerda no item selecionado
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 18
                        radius: 1.5
                        color: root.palette.accent
                        visible: actionRow.isSelected
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        // Ícone da ação
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.actionIcon
                            color: actionRow.isSelected ? root.palette.accent : root.palette.grey
                            font.family: root.palette.nerdFontFamily
                            font.pixelSize: 13
                        }

                        // Título da ação
                        Text {
                            width: parent.width - 24 - (hintBadge.visible ? (hintBadge.width + 10) : 0)
                            anchors.verticalCenter: parent.verticalCenter
                            text: (actionRow.action.title ?? "")
                            color: (actionRow.isSelected ? root.palette.foreground : root.palette.offWhite)
                            font.family: root.palette.fontFamily
                            font.pixelSize: 11
                            font.weight: actionRow.isSelected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        // Keycap badge de atalho (↵, Ctrl+↵)
                        Rectangle {
                            id: hintBadge
                            height: 20
                            width: hintText.implicitWidth + 12
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: actionRow.actionHint.length > 0
                            color: actionRow.isSelected
                                   ? Qt.rgba(root.palette.accent.r, root.palette.accent.g, root.palette.accent.b, 0.25)
                                   : root.palette.cardBackgroundSubtle
                            border.width: 1
                            border.color: actionRow.isSelected ? root.palette.accent : root.palette.borderRegular

                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: actionRow.actionHint
                                color: actionRow.isSelected ? root.palette.foreground : root.palette.grey
                                font.family: root.palette.monoFontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    HoverHandler {
                        id: rowHov
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                root.currentIndex = actionRow.index
                        }
                    }

                    TapHandler {
                        onTapped: root.actionChosen(actionRow.action.id)
                    }
                }
            }
        }

        // =====================================================================
        // RODAPÉ: GUIA DE TECLADO SUTIL
        // =====================================================================
        Item {
            width: parent.width
            height: 20

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "↑ / ↓ navegar"
                    color: root.palette.grey
                    font.family: root.palette.fontFamily
                    font.pixelSize: 9
                }

                Text {
                    text: "·"
                    color: root.palette.borderSubtle
                    font.pixelSize: 9
                }

                Text {
                    text: "↵ executar"
                    color: root.palette.grey
                    font.family: root.palette.fontFamily
                    font.pixelSize: 9
                }

                Text {
                    text: "·"
                    color: root.palette.borderSubtle
                    font.pixelSize: 9
                }

                Text {
                    text: "Esc fechar ações"
                    color: root.palette.grey
                    font.family: root.palette.fontFamily
                    font.pixelSize: 9
                }
            }
        }
    }
}
