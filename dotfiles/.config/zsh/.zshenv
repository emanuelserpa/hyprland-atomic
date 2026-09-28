# ~/.zshenv

# Zsh configuration directory
export ZDOTDIR="$HOME/.config/zsh"

# XDG base directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# XDG data lookup paths, including Flatpak exports
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share"
export XDG_SCREENSHOTS_DIR="$HOME/Imagens/screenshots"

# D-Bus session
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

# Executable search path
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.local/share/soar/bin:$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:/usr/local/bin:$PATH"

# Default programs. TERM is set by the terminal emulator; do not override it here.
export EDITOR="vim"
export TERMINAL="kitty"
export BROWSER="firefox"

# Qt and input method
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_IM_MODULE="fcitx"
export XMODIFIERS="@im=fcitx"

# Java and JetBrains IDEs
export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS="-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=lcd -Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"

# Wayland/wlroots
export WLR_DRM_NO_MODIFIERS=1

# Development tools
export RUSTC_WRAPPER="sccache"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export LEIN_HOME="$XDG_DATA_HOME/lein"
export OPAMROOT="$XDG_DATA_HOME/opam"
export DUB_HOME="$XDG_DATA_HOME/dub"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export ANSIBLE_HOME="$XDG_DATA_HOME/ansible"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"

# npm
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

# Application state and configuration
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"
export _Z_DATA="$XDG_DATA_HOME/z"
export IPFS_PATH="$XDG_CONFIG_HOME/ipfs"
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# GnuPG
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Android user data
# ANDROID_HOME is intentionally not set here: it should point to the SDK,
# not to Android's per-user data directory.
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"

# Fetch information
export PF_INFO="ascii os wm de kernel uptime pkgs memory"

# Keyring
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"

# Python virtualenvwrapper
export WORKON_HOME="$XDG_CONFIG_HOME/virtualenvs"
export VIRTUALENVWRAPPER_PYTHON="/usr/bin/python"
# source "$HOME/.local/bin/virtualenvwrapper.sh"

# Icons used by lf
export LF_ICONS="di=📁:\
fi=📃:\
tw=🤝:\
ow=📂:\
ln=⛓:\
or=❌:\
ex=🎯:\
*.txt=✍:\
*.mom=✍:\
*.me=✍:\
*.ms=✍:\
*.png=🖼:\
*.ico=🖼:\
*.jpg=📸:\
*.jpeg=📸:\
*.gif=🖼:\
*.svg=🗺:\
*.xcf=🖌:\
*.html=🌎:\
*.xml=📰:\
*.gpg=🔒:\
*.css=🎨:\
*.pdf=📚:\
*.djvu=📚:\
*.epub=📚:\
*.csv=📓:\
*.xlsx=📓:\
*.tex=📜:\
*.md=📘:\
*.r=📊:\
*.R=📊:\
*.rmd=📊:\
*.Rmd=📊:\
*.mp3=🎵:\
*.opus=🎵:\
*.ogg=🎵:\
*.m4a=🎵:\
*.flac=🎼:\
*.mkv=🎥:\
*.mp4=🎥:\
*.webm=🎥:\
*.mpeg=🎥:\
*.avi=🎥:\
*.zip=📦:\
*.rar=📦:\
*.7z=📦:\
*.tar.gz=📦:\
*.z64=🎮:\
*.v64=🎮:\
*.n64=🎮:\
*.1=ℹ:\
*.nfo=ℹ:\
*.info=ℹ:\
*.log=📙:\
*.iso=📀:\
*.img=📀:\
*.bib=🎓:\
*.ged=👪:\
*.part=💔:\
*.torrent=🔽:\
"
