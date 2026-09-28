pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool dnd: false
    property var timestamps: ({})
    property string _lastFingerprint: ""
    property double _lastSeenTime: 0

    readonly property var server: notificationServer
    readonly property var tracked: {
        const raw = notificationServer.trackedNotifications?.values
        if (!raw) return []
        const valid = []
        for (let i = 0; i < raw.length; i++) {
            const n = raw[i]
            if (n && n.tracked !== false && root.notificationHasUsefulContent(n)) {
                valid.push(n)
            }
        }
        // Return reversed copy so newest notifications always appear at the top
        return valid.reverse()
    }
    readonly property int count: tracked ? tracked.length : 0
    readonly property bool hasCritical: {
        const list = tracked
        if (!list || list.length === 0) return false
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].urgency === NotificationUrgency.Critical) {
                return true
            }
        }
        return false
    }

    signal notificationReceived(var notification)
    signal togglePopupRequested()

    function toggleDnd() {
        dnd = !dnd
    }

    function getFormattedTime(notificationId) {
        if (!notificationId) return "agora"
        const ts = timestamps[notificationId]
        if (!ts) return "agora"
        const diffSecs = Math.floor((Date.now() - ts) / 1000)
        if (diffSecs < 60) return "agora"
        const diffMins = Math.floor(diffSecs / 60)
        if (diffMins < 60) return diffMins + "m"
        const diffHours = Math.floor(diffMins / 60)
        if (diffHours < 24) return diffHours + "h"
        return Math.floor(diffHours / 24) + "d"
    }

    function formatText(str) {
        if (!str) return ""
        let s = typeof str === "string" ? str : String(str)
        return s
            .replace(/<br\s*[\/]?>/gi, '\n')
            .replace(/<[^>]+>/g, '')
            .replace(/&quot;/g, '"')
            .replace(/&apos;/g, "'")
            .replace(/&#39;/g, "'")
            .replace(/&#x27;/g, "'")
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&nbsp;/g, ' ')
            .replace(/&amp;/g, '&')
            .replace(/&#(\d+);/g, function(_, dec) {
                return String.fromCharCode(Number(dec))
            })
            .replace(/&#x([0-9a-fA-F]+);/g, function(_, hex) {
                return String.fromCharCode(parseInt(hex, 16))
            })
            .trim()
    }

    function clearAll() {
        if (!notificationServer.trackedNotifications?.values) return
        const list = notificationServer.trackedNotifications.values.slice()
        for (let i = 0; i < list.length; i++) {
            if (list[i] && typeof list[i].dismiss === "function") {
                list[i].dismiss()
            }
        }
        timestamps = ({})
    }

    function dismiss(notification) {
        if (notification && typeof notification.dismiss === "function") {
            notification.dismiss()
        }
    }

    function isBatteryAlert(n) {
        if (!n) return false
        const hay = (String(n.appName ?? "") + "\n"
            + root.formatText(n.summary) + "\n"
            + root.formatText(n.body)).toLowerCase()
        return hay.indexOf("bateria") !== -1 || hay.indexOf("battery") !== -1
    }

    // Dismiss stale low/critical battery alerts once power is connected.
    // Sender-agnostic: matches any tracked notification about battery,
    // regardless of which daemon/app emitted it.
    function dismissBatteryAlerts() {
        if (!notificationServer.trackedNotifications?.values) return
        const list = notificationServer.trackedNotifications.values.slice()
        for (let i = 0; i < list.length; i++) {
            if (root.isBatteryAlert(list[i])) {
                root.dismiss(list[i])
            }
        }
    }

    function primaryAction(notification) {
        const actions = notification?.actions
        if (!actions || actions.length === 0) return null

        for (let i = 0; i < actions.length; i++) {
            if (String(actions[i]?.identifier ?? "").toLowerCase() === "default")
                return actions[i]
        }

        for (let i = 0; i < actions.length; i++) {
            const action = actions[i]
            if (/^(open|abrir)$/i.test(String(action?.text ?? "").trim())
                    || String(action?.identifier ?? "").toLowerCase() === "open")
                return action
        }

        return null
    }

    function invokePrimaryAction(notification) {
        const action = primaryAction(notification)
        if (!action || typeof action.invoke !== "function") return false
        action.invoke()
        return true
    }

    function resolveIcon(notification) {
        if (!notification) return ""
        let name = notification.appIcon
        if (!name && notification.image && notification.image.startsWith("image://icon/"))
            name = notification.image.substring(13)
        if (!name && notification.hints)
            name = notification.hints["image-path"] || notification.hints["image_path"]
        if (name && typeof name === "string") {
            if (name.startsWith("/") || name.startsWith("file://")) return name
            return Quickshell.iconPath(name, "")
        }
        if (notification.image
                && (notification.image.startsWith("/") || notification.image.startsWith("file://")))
            return notification.image
        return ""
    }

    function isPlaceholderLabel(str) {
        const t = String(str ?? "").trim().toLowerCase()
        if (t.length === 0) return true
        const placeholders = [
            "notificação", "notificacao", "notificações", "notificacoes",
            "notification", "notifications", "new notification", "nova notificação",
            "unknown", "desconhecido", "ação", "acao", "action", "actions",
            "null", "undefined", "none", "nenhum", "empty", "vazio"
        ]
        return placeholders.indexOf(t) !== -1
    }

    function hasRealImage(n) {
        if (!n) return false
        const img = String(n.image ?? "").trim()
        if (img.length === 0) return false
        if (img.startsWith("image://icon/")) return false
        const appIcon = String(n.appIcon ?? "").trim()
        if (appIcon.length > 0 && img === appIcon) return false
        return img.startsWith("/") || img.startsWith("file://")
    }

    function hasUsefulAction(actions) {
        if (!actions || actions.length === 0) return false
        for (let i = 0; i < actions.length; i++) {
            const a = actions[i]
            const text = String(a?.text ?? a?.label ?? "").trim()
            if (text.length > 0 && !root.isPlaceholderLabel(text)) return true
        }
        return false
    }

    function notificationHasUsefulContent(n) {
        if (!n) return false
        const summary = root.formatText(n.summary)
        const body = root.formatText(n.body)
        const summaryOk = summary.length > 0 && !root.isPlaceholderLabel(summary)
        const bodyOk = body.length > 0 && !root.isPlaceholderLabel(body)
        if (summaryOk || bodyOk) return true
        if (root.hasRealImage(n)) return true
        return root.hasUsefulAction(n.actions)
    }

    function notificationFingerprint(n) {
        return String(n?.appName ?? "").trim() + "\n"
            + root.formatText(n?.summary) + "\n"
            + root.formatText(n?.body)
    }

    property IpcHandler ipc: IpcHandler {
        target: "notifications"

        function toggle() {
            root.togglePopupRequested()
        }

        function toggleDnd() {
            root.toggleDnd()
        }

        function clear() {
            root.clearAll()
        }
    }

    property NotificationServer notificationServer: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: function(n) {
            if (!n) return

            if (!root.notificationHasUsefulContent(n)) {
                console.log("NotificationState: discarded empty notification app=<" + String(n.appName ?? "") + "> summary_length=" + root.formatText(n.summary).length + " body_length=" + root.formatText(n.body).length + " actions=" + (n.actions ? n.actions.length : 0) + " id=" + n.id)
                n.tracked = false
                if (typeof n.dismiss === "function") {
                    n.dismiss()
                }
                return
            }

            const fp = root.notificationFingerprint(n)
            const now = Date.now()
            if (fp === root._lastFingerprint && (now - root._lastSeenTime) < 2000) {
                console.log("NotificationState: discarded duplicate notification id=" + n.id)
                n.tracked = false
                if (typeof n.dismiss === "function") {
                    n.dismiss()
                }
                return
            }

            n.tracked = true
            root._lastFingerprint = fp
            root._lastSeenTime = now

            // Record arrival timestamp for relative time display
            const updated = Object.assign({}, root.timestamps)
            updated[n.id] = Date.now()
            root.timestamps = updated

            const isCritical = n.urgency === NotificationUrgency.Critical
            if (!root.dnd || isCritical) {
                root.notificationReceived(n)
            }
        }
    }
}
