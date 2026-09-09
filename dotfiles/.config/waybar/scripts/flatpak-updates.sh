#!/usr/bin/env bash

if ! command -v flatpak &>/dev/null; then
  printf '%s\n' '{"text":"⚠","tooltip":"Atualizações do Flatpak\n\nFlatpak não instalado"}'
  exit 0
fi

package_list="$(flatpak remote-ls --updates --columns=name 2>/dev/null)"

if [[ -z "$package_list" ]]; then
  printf '%s\n' '{"text":"","tooltip":"Atualizações do Flatpak\n\nTudo atualizado!"}'
  exit 0
fi

package_count="$(printf '%s\n' "$package_list" | sed '/^[[:space:]]*$/d' | wc -l)"
tooltip="$(printf '%s' "$package_list" \
  | head -n 20 \
  | sed -e 's/\\/\\\\/g' \
        -e 's/"/\\"/g' \
        -e ':a;N;$!ba;s/\n/\\n/g')"

printf '{"text":" %s","tooltip":"Atualizações do Flatpak:\\n%s"}\n' \
  "$package_count" "$tooltip"
