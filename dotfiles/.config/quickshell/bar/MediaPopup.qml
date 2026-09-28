import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.components

PopupWindow {
    id: root

    required property var theme
    required property Item target
    property var player: null
    property var players: []
    property bool hoverPreview: false
    signal playerSelected(var player)
    readonly property bool containsPointer: cardHover.hovered

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6

    implicitWidth: 330
    implicitHeight: contentColumn.implicitHeight + 28

    color: "transparent"
    surfaceFormat.opaque: false
    visible: false
    grabFocus: !hoverPreview

    property bool showPlayerList: false

    readonly property var otherPlayers: (players ?? []).filter(function(p) { return p !== player })


    onVisibleChanged: {
        if (visible) {
            showPlayerList = false
            if (!hoverPreview) card.forceActiveFocus()
        }
    }

    onPlayerChanged: {
        if (root.visible && root.theme.qmlAnimationsEnabled) playerSwapAnim.restart()
    }

    onHoverPreviewChanged: {
        if (visible && !hoverPreview) card.forceActiveFocus()
    }

    readonly property string title:
        String(player?.trackTitle ?? "").trim().length > 0
        ? String(player.trackTitle).trim()
        : "Sem título"

    readonly property string artist: {
        const direct = String(player?.trackArtist ?? "").trim()
        if (direct.length > 0) return direct

        const albumArtist = String(player?.trackAlbumArtist ?? "").trim()
        if (albumArtist.length > 0) return albumArtist

        try {
            const raw = player?.metadata ? player.metadata["xesam:artist"] : null

            if (raw !== null && raw !== undefined) {
                if (Array.isArray(raw))
                    return raw.map(x => String(x).trim())
                              .filter(x => x.length > 0)
                              .join(", ")

                const value = String(raw).trim()
                if (value.length > 0)
                    return value
            }
        } catch (e) {
        }

        return "Artista desconhecido"
    }

    readonly property string album: String(player?.trackAlbum ?? "").trim()
    readonly property string artUrl: String(player?.trackArtUrl ?? "").trim()

    readonly property real lengthSec: Number(player?.length ?? 0)
    readonly property real positionSec: Number(player?.position ?? 0)

    // MPRIS position reads advance, but ordinary playback does not emit updates.
    Timer {
        interval: 250
        repeat: true
        running: root.visible && root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    readonly property color accentColor: {
        const id = ((player?.identity ?? "") + " " + (player?.dbusName ?? "")).toLowerCase()
        if (id.includes("spotify")) return root.theme.green
        if (id.includes("firefox")) return root.theme.orange
        if (id.includes("chrom")) return root.theme.blue
        return root.theme.pink
    }

    function playerName(p) {
        if (!p) return "Mídia"
        const id = String(p.identity || p.dbusName || "Mídia")
        if (id.toLowerCase().includes("spotify")) return "Spotify"
        if (id.toLowerCase().includes("firefox")) return "Firefox"
        if (id.toLowerCase().includes("zen")) return "Zen Browser"
        if (id.toLowerCase().includes("chrom")) return "Chromium"
        return id
    }

    function playerIcon(p) {
        if (!p) return ""
        const id = ((p.identity ?? "") + " " + (p.dbusName ?? "")).toLowerCase()
        if (id.includes("spotify")) return ""
        if (id.includes("firefox") || id.includes("zen")) return ""
        if (id.includes("chrom")) return ""
        if (id.includes("vlc")) return "󰕼"
        if (id.includes("mpv")) return "󰐹"
        return ""
    }

    function timeText(sec) {
        if (!isFinite(sec) || sec <= 0) return "0:00"
        const value = Math.floor(sec)
        const minutes = Math.floor(value / 60)
        const seconds = value % 60
        return minutes + ":" + String(seconds).padStart(2, "0")
    }

    function seekToFraction(fraction) {
        if (!player || lengthSec <= 0) return
        const target = Math.max(0, Math.min(lengthSec, fraction * lengthSec))
        try {
            player.position = target
        } catch (e) {
            try {
                player.setPosition(target)
            } catch (err) {}
        }
    }


    PopupCard {
        id: card
        theme: root.theme
        opened: root.visible
        anchors.fill: parent
        cardColor: root.theme.backgroundOpaque
        frameColor: root.theme.glassBorder
        Keys.onEscapePressed: root.visible = false

        HoverHandler { id: cardHover }

        // Alpha mask for the rounded ambient blur effect
        Rectangle {
            id: roundedMask
            anchors.fill: parent
            radius: card.radius
            color: "white"
            visible: false
            layer.enabled: true
        }

        Image {
            id: ambientSource
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }

        // Vibrant ambient artwork glow in the background
        MultiEffect {
            id: ambientBlur
            anchors.fill: parent
            source: ambientSource
            visible: root.artUrl.length > 0
            opacity: 0.35

            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: 1.20

            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: roundedMask

            Behavior on opacity {
                enabled: root.theme.qmlAnimationsEnabled
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        // Elegant dark glass gradient overlay for contrast and typography clarity
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(24/255, 24/255, 37/255, 0.72) }
                GradientStop { position: 0.5; color: Qt.rgba(30/255, 30/255, 46/255, 0.82) }
                GradientStop { position: 1.0; color: Qt.rgba(17/255, 17/255, 27/255, 0.92) }
            }
        }

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            // Header: Player Badge + Dropdown Trigger & Close Button
            Row {
                width: parent.width
                height: 24

                Rectangle {
                    id: playerBadge
                    height: 22
                    width: badgeRow.implicitWidth + 14
                    radius: 6
                    color: badgeHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.16)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    border.width: 1
                    border.color: badgeHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.22)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.10)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: root.playerIcon(root.player)
                            color: root.accentColor
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.playerName(root.player)
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: root.players.length > 1
                            text: root.showPlayerList ? "▴" : "▾"
                            color: root.theme.grey
                            font.family: root.theme.fontFamily
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    HoverHandler { id: badgeHover }

                    TapHandler {
                        enabled: root.players.length > 1
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.showPlayerList = !root.showPlayerList
                    }
                }

                Item {
                    width: Math.max(0, parent.width - playerBadge.width - closeBtn.width)
                    height: 1
                }

                Rectangle {
                    id: closeBtn
                    width: 22
                    height: 22
                    radius: 11
                    color: closeHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.14)
                           : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeHover.hovered ? root.theme.offWhite : root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }

                    HoverHandler { id: closeHover }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.visible = false
                    }
                }
            }

            // Expandable Player Selector Drawer (when clicked):
            // active player as a big colored card, the rest as small grey
            // cards; tapping one promotes it with an animated swap.
            Column {
                id: playerListColumn
                visible: root.showPlayerList && root.players.length > 1
                width: parent.width
                spacing: 4

                Rectangle {
                    id: playerHero
                    width: parent.width
                    height: 66
                    radius: 10
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                    border.width: 1
                    border.color: root.accentColor

                    Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on border.color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: root.playerIcon(root.player)
                            color: root.accentColor
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 22
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 72
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "Tocando agora"
                                color: root.accentColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: root.playerName(root.player)
                                color: root.theme.foreground
                                font.family: root.theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: String(root.player?.trackTitle ?? "")
                                visible: text.length > 0
                                color: root.theme.grey
                                font.family: root.theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: "󰄬"
                            color: root.theme.green
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    NumberAnimation on scale {
                        id: playerSwapAnim
                        from: 0.96
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                        running: false
                    }
                }

                // Keep the delegate model stable while MPRIS player objects
                // are destroyed. Rebinding a JS object array here crashes
                // Qt 6.11 inside Repeater/Instantiator model regeneration.
                Repeater {
                    model: 16

                    delegate: Rectangle {
                        parent: playerListColumn
                        readonly property var playerData:
                            index < root.otherPlayers.length
                            ? root.otherPlayers[index]
                            : null
                        visible: playerData !== null
                        width: parent.width
                        height: 34
                        radius: 8
                        color: playerMiniHover.hovered
                               ? Qt.rgba(255/255, 255/255, 255/255, 0.10)
                               : Qt.rgba(255/255, 255/255, 255/255, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.08)

                        Behavior on color { enabled: root.theme.qmlAnimationsEnabled; ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: root.playerIcon(playerData)
                                color: root.theme.grey
                                font.family: root.theme.nerdFontFamily
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 24
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    width: parent.width
                                    text: root.playerName(playerData)
                                    color: root.theme.offWhite
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: String(playerData?.trackTitle ?? "")
                                    visible: text.length > 0
                                    color: root.theme.grey
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        HoverHandler { id: playerMiniHover }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                root.playerSelected(playerData)
                                root.showPlayerList = false
                            }
                        }
                    }
                }
            }

            // Hero Section: Album Artwork + Track Information
            Row {
                width: parent.width
                height: 80
                spacing: 12

                // Artwork container
                Rectangle {
                    id: artContainer
                    width: 80
                    height: 80
                    radius: 12
                    color: root.theme.cardBackgroundActive
                    border.width: 1
                    border.color: root.theme.glassBorder
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Image {
                        id: artwork
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: artwork.status !== Image.Ready
                        color: root.theme.cardBackground

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: root.theme.grey
                            font.family: root.theme.nerdFontFamily
                            font.pixelSize: 26
                        }
                    }
                }

                // Track details
                Column {
                    width: parent.width - artContainer.width - 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.title
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.artist
                        color: root.accentColor
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: root.album.length > 0
                        text: root.album
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                }
            }

            // Interactive Progress Seek Bar Section
            Column {
                width: parent.width
                spacing: 4

                Item {
                    id: seekArea
                    width: parent.width
                    height: 16

                    Rectangle {
                        id: trackBg
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: 2.5
                        color: Qt.rgba(255/255, 255/255, 255/255, 0.15)

                        Rectangle {
                            id: trackFill
                            height: parent.height
                            radius: parent.radius
                            color: root.accentColor
                            width: root.lengthSec > 0
                                   ? parent.width * Math.max(0, Math.min(1, root.positionSec / root.lengthSec))
                                   : 0

                            Behavior on width {
                                enabled: root.theme.qmlAnimationsEnabled && !seekMouse.pressed
                                NumberAnimation { duration: 150 }
                            }
                        }

                        // Glowing seek handle on hover or drag
                        Rectangle {
                            width: 11
                            height: 11
                            radius: 5.5
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, trackFill.width - width / 2))
                            color: "#ffffff"
                            visible: seekMouse.containsMouse || seekMouse.pressed
                            opacity: 0.95
                        }
                    }

                    MouseArea {
                        id: seekMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(mouse) {
                            root.seekToFraction(mouse.x / width)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                root.seekToFraction(mouse.x / width)
                            }
                        }
                    }
                }

                // Time labels
                Row {
                    width: parent.width

                    Text {
                        id: leftTime
                        text: root.timeText(root.positionSec)
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }

                    Item {
                        width: Math.max(0, parent.width - leftTime.implicitWidth - rightTime.implicitWidth)
                        height: 1
                    }

                    Text {
                        id: rightTime
                        text: root.timeText(root.lengthSec)
                        color: root.theme.grey
                        font.family: root.theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            // Spacious, Centered Media Controls Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                height: 46

                // Previous Track
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: prevHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.14)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.05)
                    border.width: 1
                    border.color: prevHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.20)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.player && root.player.canGoPrevious ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: prevHover.hovered ? root.theme.foreground : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 14
                    }

                    HoverHandler { id: prevHover }

                    TapHandler {
                        enabled: root.player && root.player.canGoPrevious
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.player.previous()
                    }
                }

                // Play / Pause Hero Button
                Rectangle {
                    id: heroPlayBtn
                    width: 46
                    height: 46
                    radius: 23
                    color: playHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.24)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.15)
                    border.width: 1
                    border.color: playHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.30)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.18)
                    anchors.verticalCenter: parent.verticalCenter
                    scale: heroPlayTap.pressed ? 0.92 : 1.0

                    Behavior on scale {
                        enabled: root.theme.qmlAnimationsEnabled
                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.player?.isPlaying ? "" : ""
                        color: root.accentColor
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 18
                    }

                    HoverHandler { id: playHover }

                    TapHandler {
                        id: heroPlayTap
                        enabled: root.player && root.player.canTogglePlaying
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.player.togglePlaying()
                    }
                }

                // Next Track
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: nextHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.14)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.05)
                    border.width: 1
                    border.color: nextHover.hovered
                           ? Qt.rgba(255/255, 255/255, 255/255, 0.20)
                           : Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.player && root.player.canGoNext ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: nextHover.hovered ? root.theme.foreground : root.theme.offWhite
                        font.family: root.theme.nerdFontFamily
                        font.pixelSize: 14
                    }

                    HoverHandler { id: nextHover }

                    TapHandler {
                        enabled: root.player && root.player.canGoNext
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.player.next()
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
