#!/usr/bin/env bash
# Update runner intentionally isolates every backend.
# A failure in AUR must never prevent Flatpak or Homebrew from running.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MODE="${1:-all}"
FAILED=()

banner() {
  printf '\n%b=== %s ===%b\n\n' "$BLUE" "$1" "$NC"
}

stage_ok() {
  printf '%b✓ %s%b\n' "$GREEN" "$1" "$NC"
}

stage_fail() {
  printf '%b✗ %s%b\n' "$RED" "$1" "$NC"
  FAILED+=("$1")
}

run_repo() {
  banner "Repositórios oficiais"
  if command -v yay >/dev/null 2>&1; then
    yay -Syu --repo --noconfirm
  else
    sudo pacman -Syu --noconfirm
  fi
  local rc=$?
  [[ $rc -eq 0 ]] && stage_ok "Repos concluídos" || stage_fail "Repos falharam (código $rc)"
  return 0
}

run_aur() {
  banner "AUR"
  if ! command -v yay >/dev/null 2>&1; then
    stage_fail "AUR: yay não encontrado"
    return 0
  fi

  # Deliberadamente separado dos repositórios oficiais. Se o AUR sofrer timeout,
  # erro de PKGBUILD ou falha de origem, as próximas etapas continuam.
  yay -Syu --aur --noconfirm
  local rc=$?
  [[ $rc -eq 0 ]] && stage_ok "AUR concluído" || stage_fail "AUR falhou (código $rc)"
  return 0
}

run_flatpak() {
  banner "Flatpak"
  if ! command -v flatpak >/dev/null 2>&1; then
    printf '%b! Flatpak não instalado%b\n' "$YELLOW" "$NC"
    return 0
  fi

  flatpak update -y
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    flatpak uninstall --unused -y || true
    stage_ok "Flatpak concluído"
  else
    stage_fail "Flatpak falhou (código $rc)"
  fi
  return 0
}

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return
  fi
  for candidate in \
    /opt/brew/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    /usr/local/bin/brew \
    /opt/homebrew/bin/brew
  do
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return; }
  done
}

run_brew() {
  banner "Homebrew"
  local brew_bin
  brew_bin="$(find_brew || true)"
  if [[ -z "$brew_bin" ]]; then
    printf '%b! Homebrew não encontrado%b\n' "$YELLOW" "$NC"
    return 0
  fi

  "$brew_bin" update && "$brew_bin" upgrade
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    "$brew_bin" cleanup || true
    stage_ok "Homebrew concluído"
  else
    stage_fail "Homebrew falhou (código $rc)"
  fi
  return 0
}

case "$MODE" in
  repo) run_repo ;;
  aur) run_aur ;;
  flatpak) run_flatpak ;;
  brew) run_brew ;;
  all)
    run_repo
    run_aur
    run_flatpak
    run_brew
    ;;
  *)
    printf 'Uso: %s [all|repo|aur|flatpak|brew]\n' "$0"
    exit 2
    ;;
esac

printf '\n--------------------------------------------------\n'
if (( ${#FAILED[@]} == 0 )); then
  printf '%bTudo pronto.%b\n' "$GREEN" "$NC"
else
  printf '%bConcluído com falhas isoladas:%b\n' "$YELLOW" "$NC"
  printf '  - %s\n' "${FAILED[@]}"
  printf '\nAs outras etapas foram executadas normalmente.\n'
fi
printf '\nPressione Enter para fechar...'
read -r _
