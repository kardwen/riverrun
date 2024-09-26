# vi mode
bindkey -v

# vi mode cursor
setopt vi
KEYTIMEOUT=1
zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        echo -ne "\e[2 q"
    else
        echo -ne "\e[5 q"
    fi
}
precmd_functions+=(zle-keymap-select)
zle -N zle-keymap-select

# Edit line in vim with ctrl-e:
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Use lf to switch directories and bind it to ctrl-o
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' 'lfcd\n'

# zsh plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# coreutils color mappings
eval $(dircolors -p | perl -pe 's/^((CAP|S[ET]|O[TR]|M|E)\w+).*/$1 00/' | dircolors -)
alias ls='ls --color=auto'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# cargo (Rust)
export PATH="$PATH:$HOME/.cargo/bin"

# aliases
alias signal='flatpak run org.signal.Signal > /dev/null &!'
alias drm='flatpak run org.mozilla.firefox > /dev/null &!'

alias firefox='firefox -p felix &!'
alias night='wlsunset -L 8 -l 52 &!'
alias v='nvim'
