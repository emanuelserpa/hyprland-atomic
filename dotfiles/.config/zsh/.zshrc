# Powerlevel10k instant prompt must run before the global Zsh configuration.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load the system configuration first, then this user's ordered modules.
for system_zshrc in /etc/zsh/zshrc /etc/zshrc; do
    if [[ -r "$system_zshrc" ]]; then
        source "$system_zshrc"
        break
    fi
done
for config_file in "$ZDOTDIR"/conf.d/*.zsh; do
    [[ ! -r "$config_file" ]] || source "$config_file"
done

# Optional machine-specific overrides, loaded last.
[[ ! -r "$ZDOTDIR/.zshrc.local" ]] || source "$ZDOTDIR/.zshrc.local"
