# XDG base directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# User applications and Flatpak exports
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/soar/bin"
  "$HOME/.local/share/flatpak/exports/bin"
  /var/lib/flatpak/exports/bin
  $path
)
export PATH

# Terminal defaults. Graphical-session variables live in ~/.config/uwsm/env.
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export TERMINAL="${TERMINAL:-ghostty}"
export BROWSER="${BROWSER:-flatpak run app.zen_browser.zen}"

# Development tools following the XDG layout.
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export RUSTC_WRAPPER="${RUSTC_WRAPPER:-sccache}"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export ANSIBLE_HOME="$XDG_DATA_HOME/ansible"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
export WORKON_HOME="$XDG_DATA_HOME/virtualenvs"
export VIRTUALENVWRAPPER_PYTHON="/usr/bin/python3"

# Application state
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"
export _Z_DATA="$XDG_DATA_HOME/z"
export XDG_SCREENSHOTS_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
