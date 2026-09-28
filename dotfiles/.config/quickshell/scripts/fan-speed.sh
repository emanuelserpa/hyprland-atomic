#!/usr/bin/env bash
set -u

# Prefer ThinkPad hwmon telemetry.
for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    name="$(cat "$hw/name" 2>/dev/null || true)"

    case "$name" in
        thinkpad|thinkpad_hwmon)
            for input in "$hw"/fan*_input; do
                [[ -r "$input" ]] || continue
                value="$(cat "$input" 2>/dev/null || true)"

                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    printf '%s|%s\n' "$value" "$name"
                    exit 0
                fi
            done
            ;;
    esac
done

# Generic fallback.
for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    name="$(cat "$hw/name" 2>/dev/null || true)"

    for input in "$hw"/fan*_input; do
        [[ -r "$input" ]] || continue
        value="$(cat "$input" 2>/dev/null || true)"

        if [[ "$value" =~ ^[0-9]+$ ]]; then
            [[ -n "$name" ]] || name="hwmon"
            printf '%s|%s\n' "$value" "$name"
            exit 0
        fi
    done
done

printf '0|unavailable\n'
