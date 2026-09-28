# Emacs-style editing and common terminal key sequences.
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word

# Completion menu navigation.
command mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
zmodload zsh/complist
zstyle ':completion:*' menu select
bindkey -M menuselect '^[[A' up-line-or-history
bindkey -M menuselect '^[[B' down-line-or-history
bindkey -M menuselect '^[[C' forward-char
bindkey -M menuselect '^[[D' backward-char
bindkey -M menuselect '^M' .accept-line
