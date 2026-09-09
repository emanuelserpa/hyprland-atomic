#!/usr/bin/env bash

set -u

MODE="${1:-now}"
PLAYER="playerctld"
SEP=$'\x1f'

normalize_player() {
    local player="$1"

    case "$player" in
        firefox*)  echo "firefox" ;;
        spotify*)  echo "spotify" ;;
        chromium*) echo "chromium" ;;
        mpv*)      echo "mpv" ;;
        vlc*)      echo "vlc" ;;
        *)         echo "default" ;;
    esac
}

json_now() {
    local player="$1"
    local status="$2"
    local artist="$3"
    local title="$4"
    local album="$5"

    # Firefox/X frequentemente manda metadata vazia
    # durante a troca de uma MediaSession por outra.
    [[ -z "$title" ]] && return 0

    local player_class
    player_class="$(normalize_player "$player")"

    local icon=""

    case "$player_class" in
        firefox)  icon="" ;;
        spotify)  icon="" ;;
        chromium) icon="" ;;
        mpv)      icon="󰐹" ;;
        vlc)      icon="󰕼" ;;
    esac

    # Equivalente ao title-len = 28
    if (( ${#title} > 28 )); then
        title="${title:0:27}…"
    fi

    local text

    if [[ "$status" == "Paused" ]]; then
        text="$icon  <span alpha='70%'>$title</span>"
    else
        text="$icon  $title"
    fi

    local tooltip="<b>$title</b>"

    [[ -n "$artist" ]] && tooltip+=$'\n'"$artist"
    [[ -n "$album" ]]  && tooltip+=$'\n'"<span alpha='65%'>$album</span>"

    tooltip+=$'\n\n'"Clique: play/pause"
    tooltip+=$'\n'"Meio: anterior"
    tooltip+=$'\n'"Direito: próxima"

    jq -cn \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg status "${status,,}" \
        --arg player "$player_class" \
        '{
            text: $text,
            tooltip: $tooltip,
            class: [$status, $player]
        }'
}

json_artist() {
    local player="$1"
    local status="$2"
    local artist="$3"

    [[ -z "$artist" ]] && return 0

    local player_class
    player_class="$(normalize_player "$player")"

    if (( ${#artist} > 22 )); then
        artist="${artist:0:21}…"
    fi

    jq -cn \
        --arg text "• $artist" \
        --arg status "${status,,}" \
        --arg player "$player_class" \
        '{
            text: $text,
            class: [$status, $player]
        }'
}

json_toggle() {
    local player="$1"
    local status="$2"

    local player_class
    player_class="$(normalize_player "$player")"

    local icon

    case "$status" in
        Playing)
            icon=""
            ;;
        Paused|Stopped|*)
            icon=""
            ;;
    esac

    jq -cn \
        --arg text "$icon" \
        --arg status "${status,,}" \
        --arg player "$player_class" \
        '{
            text: $text,
            class: [$status, $player]
        }'
}

while true; do
    while IFS="$SEP" read -r player status artist title album; do
        [[ -z "${player:-}" ]] && continue

        case "$MODE" in
            now)
                json_now \
                    "$player" \
                    "$status" \
                    "$artist" \
                    "$title" \
                    "$album"
                ;;

            artist)
                json_artist \
                    "$player" \
                    "$status" \
                    "$artist"
                ;;

            toggle)
                json_toggle \
                    "$player" \
                    "$status"
                ;;

            *)
                echo "Modo inválido: $MODE" >&2
                exit 1
                ;;
        esac

    done < <(
        playerctl \
            --player="$PLAYER" \
            metadata \
            --follow \
            --format $'{{playerName}}\x1f{{status}}\x1f{{artist}}\x1f{{title}}\x1f{{album}}' \
            2>/dev/null
    )

    # Se playerctl/libplayerctl morrer,
    # só este subprocesso cai.
    # A Waybar continua rodando e reconectamos.
    sleep 0.5
done
