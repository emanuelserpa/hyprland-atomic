import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.services

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        right: true
    }

    margins.top: 45
    margins.right: 12
    implicitWidth: 350
    implicitHeight: Math.max(1, toastColumn.implicitHeight)

    exclusionMode: ExclusionMode.Ignore
    focusable: false
    aboveWindows: true
    color: "transparent"
    surfaceFormat.opaque: false
    visible: root.activeToasts.length > 0

    readonly property var theme: Theme {}

    property var activeToasts: []

    Connections {
        target: NotificationState

        function onNotificationReceived(n) {
            root.addToast(n)
        }
    }

    function addToast(n) {
        if (!n || !NotificationState.notificationHasUsefulContent(n)) return

        let timeout = 5500
        if (n.urgency === NotificationUrgency.Critical) {
            timeout = 0
        } else if (n.urgency === NotificationUrgency.Low) {
            timeout = 3500
        }

        const toastItem = {
            "id": n.id,
            "notification": n,
            "timeout": timeout,
            "created": Date.now()
        }

        // Limit to at most 3 simultaneous toasts on screen
        const list = root.activeToasts.slice()
        if (list.length >= 3) {
            list.pop()
        }
        list.unshift(toastItem)
        root.activeToasts = list
    }

    function removeToast(toastId) {
        root.activeToasts = root.activeToasts.filter(t => t.id !== toastId)
        root.closingIds = root.closingIds.filter(id => id !== toastId)
    }

    // Animated close: fade + collapse first, remove from model after.
    property var closingIds: []

    function closeToast(toastId) {
        if (root.closingIds.indexOf(toastId) !== -1) return
        const ids = root.closingIds.slice()
        ids.push(toastId)
        root.closingIds = ids
    }

    Column {
        id: toastColumn
        width: parent.width
        spacing: 8

        Repeater {
            model: root.activeToasts

            delegate: Rectangle {
                id: toastCard
                required property var modelData
                required property int index

                readonly property var n: modelData.notification
                readonly property bool isCritical: n && n.urgency === NotificationUrgency.Critical
                readonly property bool hasContent: NotificationState.notificationHasUsefulContent(n)

                visible: hasContent
                width: parent.width
                implicitHeight: (dying || !hasContent) ? 0 : (toastContent.implicitHeight + 20)
                radius: root.theme.radiusPopup
                color: root.theme.notificationBackground
                border.width: 1
                border.color: isCritical
                              ? root.theme.red
                              : (cardHover.hovered ? root.theme.pillBorderHover : root.theme.glassBorder)
                opacity: dying ? 0 : (entered ? 1 : 0)

                readonly property bool dying: root.closingIds.indexOf(modelData.id) !== -1
                property bool entered: false

                Behavior on opacity { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: root.theme.motionStandard; easing.type: root.theme.motionEasing } }
                Behavior on implicitHeight { enabled: root.theme.qmlAnimationsEnabled; NumberAnimation { duration: root.theme.motionLayout; easing.type: root.theme.motionEasing } }

                Component.onCompleted: {
                    entered = true
                }

                onDyingChanged: {
                    if (dying)
                        removeTimer.start()
                }

                Timer {
                    id: removeTimer
                    interval: root.theme.motionLayout
                    repeat: false
                    onTriggered: root.removeToast(modelData.id)
                }

                Behavior on border.color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: root.theme.motionFast } }

                Timer {
                    id: dismissTimer
                    interval: modelData.timeout
                    running: modelData.timeout > 0 && !cardHover.hovered
                    repeat: false
                    onTriggered: root.closeToast(modelData.id)
                }

                HoverHandler {
                    id: cardHover
                }

                readonly property bool hasBodyImage: {
                    if (!n?.image || n.image.length === 0) return false
                    if (n.image.startsWith("image://icon/")) return false
                    if (n.image === n.appIcon) return false
                    return true
                }

                Column {
                    id: toastContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 8

                    // Header: App icon, app name & close button
                    Item {
                        width: parent.width
                        height: 18

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            HoverHandler {
                                cursorShape: NotificationState.primaryAction(toastCard.n)
                                             ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }

                            TapHandler {
                                onTapped: {
                                    if (NotificationState.invokePrimaryAction(toastCard.n))
                                        root.closeToast(toastCard.modelData.id)
                                }
                            }

                            Image {
                                id: headerIcon
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                source: NotificationState.resolveIcon(toastCard.n)
                                visible: status === Image.Ready && source.toString().length > 0
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !headerIcon.visible
                                text: toastCard.isCritical ? "󰀦" : "󰂚"
                                color: toastCard.isCritical ? root.theme.red : root.theme.blue
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(toastCard.n?.appName || "Notificação")
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: closeBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: closeHover.hovered
                                   ? Qt.rgba(255/255, 255/255, 255/255, 0.15)
                                   : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: closeHover.hovered ? root.theme.offWhite : root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                            }

                            HoverHandler {
                                id: closeHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    const toastId = modelData.id
                                    NotificationState.dismiss(toastCard.n)
                                    root.closeToast(toastId)
                                }
                            }
                        }
                    }

                    // Content: Title and Body (+ attached image if provided)
                    Row {
                        width: parent.width
                        spacing: 10

                        HoverHandler {
                            cursorShape: NotificationState.primaryAction(toastCard.n)
                                         ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }

                        TapHandler {
                            onTapped: {
                                if (NotificationState.invokePrimaryAction(toastCard.n))
                                    root.closeToast(toastCard.modelData.id)
                            }
                        }

                        Rectangle {
                            id: bodyImgContainer
                            width: 48
                            height: 48
                            radius: 8
                            clip: true
                            color: "transparent"
                            visible: toastCard.hasBodyImage && bodyImage.status === Image.Ready
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: bodyImage
                                anchors.fill: parent
                                source: toastCard.hasBodyImage ? (toastCard.n.image || "") : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                        }

                        Column {
                            width: parent.width - (bodyImgContainer.visible ? (bodyImgContainer.width + 10) : 0)
                            spacing: 3

                            Text {
                                width: parent.width
                                text: NotificationState.formatText(toastCard.n?.summary)
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                visible: text.length > 0
                            }

                            Text {
                                width: parent.width
                                text: NotificationState.formatText(toastCard.n?.body)
                                color: root.theme.offWhite
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 3
                                visible: text.length > 0
                            }
                        }
                    }

                    // Actions Row (if notification actions are available)
                    Row {
                        width: parent.width
                        spacing: 6
                        visible: toastCard.n && toastCard.n.actions && toastCard.n.actions.length > 0

                        Repeater {
                            model: toastCard.n ? toastCard.n.actions : []

                            delegate: Rectangle {
                                required property var modelData
                                height: 24
                                width: actionLabel.implicitWidth + 16
                                radius: root.theme.pillRadius
                                color: actHover.hovered ? root.theme.pillBackgroundHover : root.theme.pillBackground
                                border.width: 1
                                border.color: actHover.hovered ? root.theme.pillBorderHover : root.theme.pillBorder

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: String(modelData.text || "Ação")
                                    color: actHover.hovered ? root.theme.foreground : root.theme.offWhite
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }

                                HoverHandler {
                                    id: actHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        if (modelData && typeof modelData.invoke === "function") {
                                            modelData.invoke()
                                        }
                                        root.closeToast(toastCard.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
