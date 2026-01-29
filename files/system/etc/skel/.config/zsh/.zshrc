# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Deduplicate PATH
typeset -U path PATH

# --- Bazzite/System Integration ---
# Source /etc/profile to load system-wide settings (ujust, etc.)
if [[ -e /etc/profile ]]; then
    emulate sh -c 'source /etc/profile'
fi

# 1. Source the global Grml/Arch Zsh configuration (if it exists)
if [[ -f /etc/zsh/zshrc ]]; then
    source /etc/zsh/zshrc
fi

# Source downloaded Grml Zsh config
if [[ -f ${ZDOTDIR:-$HOME}/.grml-zshrc ]]; then
    source ${ZDOTDIR:-$HOME}/.grml-zshrc
fi

# 1.1. Força o modo de edição padrão (desativa o modo Vi/Normal)
bindkey -e

# 1.2. Corrige as teclas Home/End (especialmente úteis no seu teclado)
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey "^[[3~" delete-char
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word

# 1.3. Configura a navegação nas sugestões com as setas
# Inicializa o sistema de completação (se o Grml não tiver feito)
autoload -Uz compinit && compinit

# Configura o Menu de Seleção Visual
zmodload zsh/complist
zstyle ':completion:*' menu select

# Mapeamentos para navegar no menu com as setas
bindkey -M menuselect '^[[A' up-line-or-history
bindkey -M menuselect '^[[B' down-line-or-history
bindkey -M menuselect '^[[C' forward-char
bindkey -M menuselect '^[[D' backward-char

# Aceita com Enter, cancela com Esc (opcional)
bindkey -M menuselect '^M' .accept-line

# 2. Source Powerlevel10k Theme (ALWAYS load this, and load it AFTER global config)
if [[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
fi

# 3. Source your local customizations
if [[ -f ${ZDOTDIR:-$HOME}/.zshrc.local ]]; then
    source ${ZDOTDIR:-$HOME}/.zshrc.local
fi

# History Configuration
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# History Options
setopt EXTENDED_HISTORY      # Write timestamps to history
setopt SHARE_HISTORY         # Share history between terminals immediately
setopt HIST_IGNORE_DUPS      # Don't record same command twice in a row
setopt HIST_IGNORE_SPACE     # Don't record commands starting with a space

# 4. Load Powerlevel10k config settings
#[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
[[ ! -f "$ZDOTDIR/.p10k.zsh" ]] || source "$ZDOTDIR/.p10k.zsh"
