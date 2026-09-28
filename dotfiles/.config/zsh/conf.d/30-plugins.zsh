# Prompt theme, loaded before the prompt settings module.
if (( $+functions[zinit] )); then
    zinit ice depth=1
    zinit light romkatv/powerlevel10k
elif [[ -r /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
fi

# FZF: Ctrl-R history, Ctrl-T files, Alt-C directories.
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# Deja and history search, followed by syntax highlighting (load last).
if (( $+functions[zinit] )); then
    zinit ice depth=1 pick"deja.plugin.zsh"
    zinit light Giammarco-Ferranti/deja
    zinit ice depth=1 pick"zsh-history-substring-search.zsh"
    zinit light zsh-users/zsh-history-substring-search
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    zinit ice depth=1 pick"zsh-syntax-highlighting.zsh"
    zinit light zsh-users/zsh-syntax-highlighting
else
    [[ ! -r "$XDG_DATA_HOME/deja/init.zsh" ]] || source "$XDG_DATA_HOME/deja/init.zsh"
    [[ ! -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] || source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey '^[[A' history-substring-search-up 2>/dev/null
    bindkey '^[[B' history-substring-search-down 2>/dev/null
    [[ ! -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] || source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
