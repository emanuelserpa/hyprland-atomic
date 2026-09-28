#!/usr/bin/env bash
# =============================================================================
# compositor-dispatch.sh — Agnostic Compositor Dispatcher
# =============================================================================
# Encapsulates compositor-specific IPC and syntax (Lua vs classic conf) so that
# visible QML surfaces remain decoupled from compositor internal syntax.
# =============================================================================
set -euo pipefail

ACTION="${1:-}"

if [ -z "$ACTION" ]; then
    echo "Usage: compositor-dispatch.sh <workspace|window> [args...]" >&2
    exit 1
fi

# labwc has no IPC: numeric desktop switching is injected as Logo+N through
# wtype, which requires matching W-1..N keybinds (GoToDesktop) in rc.xml.
# Checked before hyprctl because the binary may exist while idle in a labwc
# session. Only numeric targets are supported (no e±1 scrolling, no direct
# window focus).
if [ -n "${LABWC_PID:-}" ] || [[ "${XDG_CURRENT_DESKTOP:-}" == *labwc* ]]; then
    case "$ACTION" in
        workspace)
            TARGET="${2:-1}"
            if [[ ! "$TARGET" =~ ^([1-9]|10)$ ]]; then
                echo "labwc: only numeric desktops supported (got '$TARGET')" >&2
                exit 1
            fi
            if ! command -v wtype >/dev/null 2>&1; then
                echo "labwc: wtype not found" >&2
                exit 1
            fi
            if [ "$TARGET" = 10 ]; then TARGET=0; fi
            exec wtype -M logo -k "$TARGET"
            ;;
        window)
            echo "labwc: direct window focus unsupported" >&2
            exit 1
            ;;
        *)
            echo "Unknown action: $ACTION" >&2
            exit 1
            ;;
    esac
fi

# Hyprland dispatch handling
if command -v hyprctl >/dev/null 2>&1; then
    case "$ACTION" in
        workspace)
            TARGET="${2:-1}"
            # 1. Try Lua dispatcher (Hyprland 0.55+ with Lua configuration)
            if hyprctl dispatch "hl.dsp.focus({ workspace = \"$TARGET\" })" >/dev/null 2>&1; then
                exit 0
            fi
            # 2. Fallback to classic hyprlang dispatcher syntax
            exec hyprctl dispatch workspace "$TARGET"
            ;;

        window)
            ADDR="${2:-}"
            WS="${3:-}"
            [ -z "$ADDR" ] && exit 1

            if [ -n "$WS" ] && [[ ! "$WS" =~ ^special: ]]; then
                LUA="(function() hl.dispatch(hl.dsp.focus({ workspace = \"$WS\" })); return hl.dsp.focus({ window = \"address:$ADDR\" }) end)()"
                if hyprctl dispatch "$LUA" >/dev/null 2>&1; then
                    exit 0
                fi
                hyprctl dispatch workspace "$WS" >/dev/null 2>&1 || true
            else
                LUA="hl.dsp.focus({ window = \"address:$ADDR\" })"
                if hyprctl dispatch "$LUA" >/dev/null 2>&1; then
                    exit 0
                fi
            fi

            # Fallback to classic hyprlang dispatcher syntax
            exec hyprctl dispatch focuswindow "address:$ADDR"
            ;;

        close-window)
            ADDR="${2:-}"
            [ -z "$ADDR" ] && exit 1
            exec hyprctl dispatch killwindow "address:$ADDR"
            ;;

        *)
            echo "Unknown action: $ACTION" >&2
            exit 1
            ;;
    esac
fi

# Fallback for future compositor support (e.g. swaymsg, niri msg)
echo "No supported compositor detected or command failed." >&2
exit 1
