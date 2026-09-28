# SSH host completion and completion cache.
zstyle ':completion:*:ssh:*' hosts off
zstyle ':completion:*:(ssh|scp|rsync):*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:hosts' known-hosts-files "$HOME/.ssh/known_hosts"
zstyle ':completion:*' rehash true
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
