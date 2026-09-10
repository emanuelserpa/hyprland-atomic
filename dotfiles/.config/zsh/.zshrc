# Fedora's global interactive configuration, when present.
[[ -r /etc/zshrc ]] && source /etc/zshrc

autoload -Uz compinit vcs_info up-line-or-beginning-search down-line-or-beginning-search
mkdir -p -- "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
bindkey -M menuselect '^[[A' up-line-or-history
bindkey -M menuselect '^[[B' down-line-or-history
bindkey -M menuselect '^[[C' forward-char
bindkey -M menuselect '^[[D' backward-char
bindkey -M menuselect '^M' .accept-line

# Keep history private and outside the configuration repository.
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p -m 700 -- "${HISTFILE:h}"
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Load Fedora-packaged plugins without assuming Arch paths.
for plugin in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -r "$plugin" ]] && source "$plugin" && break
done
for plugin in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "$plugin" ]] && source "$plugin" && break
done

# Portable prompt with Git information; no theme checkout is required.
zstyle ':vcs_info:git:*' formats '%F{magenta}%b%f'
precmd() { vcs_info }
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f ${vcs_info_msg_0_} %(?.%F{green}.%F{red})❯%f '
RPROMPT='%F{yellow}%*%f'

[[ -r "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
