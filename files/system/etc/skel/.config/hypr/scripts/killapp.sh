#!/bin/bash

# --- 1. SETUP ---
# Detect theme (defaults to hicolor)
CURRENT_THEME=$(grep 'gtk-icon-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2 | tr -d '[:space:]')
[ -z "$CURRENT_THEME" ] && CURRENT_THEME="hicolor"

# --- 2. CONFIG: MANUAL FIXES ---
declare -A MAN_FIXES=(
    ["smartcode-stremio"]="com.stremio.Stremio" 
    ["com.stremio.stremio"]="com.stremio.Stremio"
    ["Stremio"]="com.stremio.Stremio"
    ["com.github.rafostar.Clapper"]="com.github.rafostar.Clapper"
)

# --- 3. ICON LOGIC ---
find_icon() {
    local class=$1
    local paths=(
        "$HOME/.local/share/icons/$CURRENT_THEME"
        "/usr/share/icons/$CURRENT_THEME"
        "$HOME/.local/share/icons/hicolor"
        "/usr/share/icons/hicolor"
        "$HOME/.local/share/flatpak/exports/share/icons/hicolor"
        "/var/lib/flatpak/exports/share/icons/hicolor"
        "/usr/share/pixmaps"
    )

    local names=("$class" "${class,,}")
    if [ -n "${MAN_FIXES[$class]}" ]; then names+=("${MAN_FIXES[$class]}"); fi
    if [[ "$class" == *"."* ]]; then names+=("$(echo "$class" | awk -F. '{print $NF}' | tr '[:upper:]' '[:lower:]')"); fi
    if [[ "$class" == *"-"* ]]; then names+=("$(echo "$class" | awk -F- '{print $NF}' | tr '[:upper:]' '[:lower:]')"); fi

    for path in "${paths[@]}"; do
        [ ! -d "$path" ] && continue
        for name in "${names[@]}"; do
            for size in "48x48/apps" "scalable/apps" "apps" "256x256/apps" "128x128/apps"; do
                if [ -f "$path/$size/$name.svg" ]; then echo "$path/$size/$name.svg"; return; fi
                if [ -f "$path/$size/$name.png" ]; then echo "$path/$size/$name.png"; return; fi
            done
            local found=$(find "$path" -maxdepth 4 \( -iname "$name.svg" -o -iname "$name.png" \) -print -quit 2>/dev/null)
            if [ -n "$found" ]; then echo "$found"; return; fi
        done
    done
}

# --- 4. GENERATE LIST ---
# CHANGED: We now grab the PID (.pid) instead of the Address (.address)
window_list=$(hyprctl clients -j | jq -r '.[] | "\(.class)\t\(.pid)\t\(.title)"' | while IFS=$'\t' read -r class pid title; do
    icon_path=$(find_icon "$class")
    if [ -n "$icon_path" ]; then
        echo "img:${icon_path}:text:${pid} ${class} - ${title}"
    else
        echo "text:${pid} ${class} - ${title}"
    fi
done)

# --- 5. EXECUTE ---
selected=$(echo "$window_list" | wofi --dmenu --allow-images -p "Kill App" -i)

# CHANGED: Extract PID (first column) and kill the process
# We strip the image tag if present, then take the first word (PID)
pid=$(echo "$selected" | sed 's/^img:.*:text://' | awk '{print $1}')

# Check if PID is a number before killing
if [[ "$pid" =~ ^[0-9]+$ ]]; then
    kill -9 "$pid"
fi
