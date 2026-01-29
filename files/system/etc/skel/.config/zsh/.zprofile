# Add local bin to PATH
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"

alias rm='trash'
alias lf='lfrun'
alias cp='cp -i'
alias mv='mv -i'
# If running from tty1 start sway
#[ "$(tty)" = "/dev/tty1" ] && exec sway
