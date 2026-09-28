import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.services


PopupWindow {
    id: root

    required property var theme
    required property Item target

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    readonly property real availableContentHeight: NotificationState.count > 0
        ? Math.max(340, Math.min(560, notifListCol.implicitHeight))
        : 220

    implicitWidth: 400
    implicitHeight: card.implicitHeight

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: true

    function toggle() {

        root.visible = !root.visible
    }

    onVisibleChanged: {
        if (visible) card.forceActiveFocus()
    }

    PopupCard {
        id: card
        theme: root.theme
        cardColor: root.theme.notificationBackground
        opened: root.visible
        anchors.fill: parent
        implicitWidth: 400
        implicitHeight: mainCol.implicitHeight + 24
        frameColor: root.theme.glassBorder
        Keys.onEscapePressed: root.visible = false

        Column {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header Row: Title, Count badge, DND toggle, Clear all & Close
            Item {
                id: headerRow
                width: parent.width
                height: 26
                implicitHeight: 26

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: "󰂜"
                        color: root.theme.cyan
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Notificações"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        visible: NotificationState.count > 0
                        width: Math.max(18, countText.implicitWidth + 8)
                        height: 18
                        radius: 9
                        color: Qt.rgba(137/255, 180/255, 250/255, 0.20)
                        border.width: 1
                        border.color: root.theme.blue
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: "" + NotificationState.count
                            color: root.theme.blue
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // DND Toggle Button
                    Rectangle {
                        width: dndRow.implicitWidth + 12
                        height: 24
                        radius: root.theme.pillRadius
                        color: NotificationState.dnd
                               ? Qt.rgba(243/255, 139/255, 168/255, 0.22)
                               : (dndHover.hovered ? root.theme.pillBackgroundHover : root.theme.pillBackground)
                        border.width: 1
                        border.color: NotificationState.dnd
                                      ? root.theme.red
                                      : (dndHover.hovered ? root.theme.pillBorderHover : root.theme.pillBorder)

                        Row {
                            id: dndRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: NotificationState.dnd ? "󰪓" : "󰂜"
                                color: NotificationState.dnd ? root.theme.red : root.theme.offWhite
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: NotificationState.dnd ? "Silenciado" : "DND"
                                color: NotificationState.dnd ? root.theme.red : root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        HoverHandler {
                            id: dndHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: NotificationState.toggleDnd()
                        }
                    }

                    // Clear All Button (only when there are notifications)
                    Rectangle {
                        visible: NotificationState.count > 0
                        width: clearRow.implicitWidth + 12
                        height: 24
                        radius: root.theme.pillRadius
                        color: clearHover.hovered ? root.theme.pillBackgroundHover : root.theme.pillBackground
                        border.width: 1
                        border.color: clearHover.hovered ? root.theme.pillBorderHover : root.theme.pillBorder

                        Row {
                            id: clearRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰅖"
                                color: clearHover.hovered ? root.theme.foreground : root.theme.grey
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Limpar"
                                color: clearHover.hovered ? root.theme.foreground : root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        HoverHandler {
                            id: clearHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: NotificationState.clearAll()
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: root.theme.glassBorderSubtle
            }

            // Empty State view
            Item {
                visible: NotificationState.count === 0
                width: parent.width
                height: 160
                implicitHeight: visible ? 160 : 0

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂜"
                        color: root.theme.grey
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 36
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Sem notificações"
                        color: root.theme.offWhite
                        font.family: root.theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Tudo limpo por aqui"
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            // Notifications List view
            Item {
                id: listContainer
                visible: NotificationState.count > 0
                width: parent.width
                height: root.availableContentHeight
                implicitHeight: visible ? root.availableContentHeight : 0

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: notifListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    // Shared scroll handling follows the shell's conventional
                    // wheel direction; mouse notches use direct steps so
                    // Flickable flick velocity cannot reverse the direction.
                    WheelKinetic {
                        id: wheelKinetic
                        target: flickable
                    }

                    // Entry point for the scrollbar and other callers.
                    function scrollWheel(event) {
                        wheelKinetic.handle(event)
                    }

                    Column {
                        id: notifListCol
                        width: parent.width - (scrollBar.visible ? 10 : 0)
                        spacing: 8

                    Repeater {
                        model: NotificationState.tracked

                        delegate: Rectangle {
                            id: notifItemCard
                            required property var modelData

                            readonly property bool isCritical: modelData && modelData.urgency === NotificationUrgency.Critical
                            readonly property bool hasContent: NotificationState.notificationHasUsefulContent(modelData)
                            readonly property bool hasBodyImage: {
                                if (!modelData?.image || modelData.image.length === 0) return false
                                if (modelData.image.startsWith("image://icon/")) return false
                                if (modelData.image === modelData.appIcon) return false
                                return true
                            }

                            visible: hasContent
                            width: parent.width
                            height: implicitHeight
                            implicitHeight: hasContent ? (notifContentCol.implicitHeight + 16) : 0
                            radius: root.theme.radiusMd
                            color: notifHover.hovered ? root.theme.pillBackgroundHover : root.theme.pillBackground
                            border.width: 1
                            border.color: isCritical
                                          ? root.theme.red
                                          : (notifHover.hovered ? root.theme.pillBorderHover : root.theme.pillBorder)

                            Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 120 } }
                            Behavior on border.color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 120 } }

                            HoverHandler {
                                id: notifHover
                            }

                            Column {
                                id: notifContentCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                // App header row
                                Item {
                                    width: parent.width
                                    height: 16

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 5

                                        HoverHandler {
                                            cursorShape: NotificationState.primaryAction(notifItemCard.modelData)
                                                         ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        }

                                        TapHandler {
                                            onTapped: NotificationState.invokePrimaryAction(notifItemCard.modelData)
                                        }

                                        Image {
                                            id: appIconImg
                                            width: 13
                                            height: 13
                                            anchors.verticalCenter: parent.verticalCenter
                                            source: NotificationState.resolveIcon(notifItemCard.modelData)
                                            visible: status === Image.Ready && source.toString().length > 0
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: !appIconImg.visible
                                            text: notifItemCard.isCritical ? "󰀦" : "󰂚"
                                            color: notifItemCard.isCritical ? root.theme.red : root.theme.blue
                                            font.family: root.theme.nerdFontFamily
                                            font.pixelSize: 10
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: String(notifItemCard.modelData?.appName || "Notificação")
                                            color: root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Relative timestamp & Dismiss single notification button
                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: NotificationState.getFormattedTime(notifItemCard.modelData?.id)
                                            color: root.theme.grey
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 9
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: itemCloseHover.hovered
                                                   ? Qt.rgba(255/255, 255/255, 255/255, 0.15)
                                                   : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: itemCloseHover.hovered ? root.theme.offWhite : root.theme.grey
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 9
                                            }

                                            HoverHandler {
                                                id: itemCloseHover
                                                cursorShape: Qt.PointingHandCursor
                                            }

                                            TapHandler {
                                                onTapped: {
                                                    if (notifItemCard.modelData && typeof notifItemCard.modelData.dismiss === "function") {
                                                        notifItemCard.modelData.dismiss()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Title and body
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    HoverHandler {
                                        cursorShape: NotificationState.primaryAction(notifItemCard.modelData)
                                                     ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    }

                                    TapHandler {
                                        onTapped: NotificationState.invokePrimaryAction(notifItemCard.modelData)
                                    }

                                    Rectangle {
                                        id: itemImgContainer
                                        width: 40
                                        height: 40
                                        radius: 6
                                        clip: true
                                        color: "transparent"
                                        visible: notifItemCard.hasBodyImage && itemImg.status === Image.Ready
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            id: itemImg
                                            anchors.fill: parent
                                            source: notifItemCard.hasBodyImage ? (notifItemCard.modelData.image || "") : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }
                                    }

                                    Column {
                                        width: parent.width - (itemImgContainer.visible ? (itemImgContainer.width + 8) : 0)
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: NotificationState.formatText(notifItemCard.modelData?.summary)
                                            color: root.theme.foreground
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            wrapMode: Text.Wrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            visible: text.length > 0
                                        }

                                        Text {
                                            width: parent.width
                                            text: NotificationState.formatText(notifItemCard.modelData?.body)
                                            color: root.theme.offWhite
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 4
                                            visible: text.length > 0
                                        }
                                    }
                                }

                                // Action Buttons
                                Row {
                                    width: parent.width
                                    spacing: 6
                                    visible: notifItemCard.modelData && notifItemCard.modelData.actions && notifItemCard.modelData.actions.length > 0

                                    Repeater {
                                        model: notifItemCard.modelData ? notifItemCard.modelData.actions : []

                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 22
                                            width: btnLabel.implicitWidth + 14
                                            radius: root.theme.pillRadius
                                            color: notifBtnHover.hovered ? root.theme.pillBackgroundHover : root.theme.pillBackground
                                            border.width: 1
                                            border.color: notifBtnHover.hovered ? root.theme.pillBorderHover : root.theme.pillBorder

                                            Text {
                                                id: btnLabel
                                                anchors.centerIn: parent
                                                text: String(modelData.text || "Ação")
                                                color: notifBtnHover.hovered ? root.theme.foreground : root.theme.offWhite
                                                font.family: root.theme.fontFamily
                                                font.pixelSize: 9
                                                font.weight: Font.Medium
                                            }

                                            HoverHandler {
                                                id: notifBtnHover
                                                cursorShape: Qt.PointingHandCursor
                                            }

                                            TapHandler {
                                                onTapped: {
                                                    if (modelData && typeof modelData.invoke === "function") {
                                                        modelData.invoke()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 8
                    }
                }
            }

                ScrollBar {
                    id: scrollBar
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    target: flickable
                    theme: root.theme
                    wheelController: wheelKinetic
                    thumbColor: root.theme.blue
                    idleOpacity: 0.4
                    hoverOpacity: 1
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }
}
