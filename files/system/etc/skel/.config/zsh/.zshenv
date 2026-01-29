#Bootstrap

export TERM=xterm-256color
# Adds `~/.local/bin` to $PATH
#export PATH="$PATH:$(du "$HOME/bin/" | cut -f2 | paste -sd ':')"
#export PATH="$PATH:$(du "$HOME/.local/bin" | cut -f2 | paste -sd ':')"

#IBUS
export QT_QPA_PLATFORMTHEME="qt5ct"
#export GTK2_RC_FILES=/usr/share/themes/Ant-Dracula/gtk-2.0/gtkrc
#export QT_QPA_PLATFORMTHEME=gtk2
#export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
#export GTK_IM_MODULE=ibus
#export XMODIFIERS=@im=ibus
#export QT_IM_MODULE=ibus
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
RUSTC_WRAPPER=sccache

# Fixes issues on jetbrains ides
export _JAVA_AWT_WM_NONREPARENTING=1
#export _JAVA_OPTIONS='-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'
#export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=lcd'
export _JAVA_OPTIONS="-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=lcd -Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export WLR_DRM_NO_MODIFIERS=1

#Misc
export XDG_SCREENSHOTS_DIR="/home/emanuel/Imagens/screenshots"

# Default programs:
export EDITOR="nvim"
export TERMINAL="ghostty"
export BROWSER="firefox"

#XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

#XDG envs
export XDG_RUNTIME_DIR=/run/user/$(id -ru)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -ru)/bus
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export LEIN_HOME="$XDG_DATA_HOME"/lein
export GOPATH="$XDG_DATA_HOME"/go
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default
export _Z_DATA="$XDG_DATA_HOME/z"
export IPFS_PATH=$XDG_CONFIG_HOME/ipfs
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export OPAMROOT="$XDG_DATA_HOME/opam"
export GOMODCACHE="$XDG_CACHE_HOME"/go/mod
export SQLITE_HISTORY="$XDG_CACHE_HOME"/sqlite_history
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"
export ANDROID_HOME="$XDG_DATA_HOME"/android                                  
export DUB_HOME="$XDG_DATA_HOME/dub"
export DOTNET_CLI_HOME="$XDG_DATA_HOME"/dotnet
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
export ANSIBLE_HOME="$XDG_DATA_HOME"/ansible
alias adb='HOME="$XDG_DATA_HOME"/android adb'
export GNUPGHOME="$XDG_DATA_HOME"/gnupg

#Fetch
export PF_INFO="ascii os wm de kernel uptime pkgs memory"
#XDG_CURRENT_DESKTOP="sway"
#Keyring
export SSH_AUTH_SOCK=/run/user/$(id -u)/keyring/ssh

#flatpak



#Virtualenv
export WORKON_HOME=$XDG_CONFIG_HOME/virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
#source $HOME/.local/bin/virtualenvwrapper.sh


# This is the list for lf icons:
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

