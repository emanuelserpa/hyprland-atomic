# Homebrew provides Deja and a few shell integrations.
if (( $+commands[brew] )); then
    eval "$(brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Bootstrap Zinit on first use, then load it for the plugin module.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -r "$ZINIT_HOME/zinit.zsh" ]] && (( $+commands[git] )); then
    command mkdir -p "${ZINIT_HOME:h}"
    command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
[[ ! -r "$ZINIT_HOME/zinit.zsh" ]] || source "$ZINIT_HOME/zinit.zsh"
