# vi mode
bindkey -v
setopt vi
KEYTIMEOUT=1

# vi mode cursor fix
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

# Plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt theme
autoload -Uz promptinit
promptinit
prompt fire red magenta blue white white white

# Coreutils color mappings
eval $(dircolors -p | perl -pe 's/^((CAP|S[ET]|O[TR]|M|E)\w+).*/$1 00/' | dircolors -)

# Environment variables

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Rust
export PATH="$PATH:$HOME/.cargo/bin"

# XDG directory for user-specific executables
export PATH=$PATH:$HOME/.local/bin

export GPG_TTY=$(tty)

# Aliases
alias ls='ls --color=auto'
alias firefox='firefox -p felix &!'
alias night='pkill -f wlsunset; wlsunset -L 8 -l 52 -T 6000 &> /dev/null &!'
alias day='pkill -f wlsunset'
alias v='nvim'
alias c='clear'
alias g='git'
alias lg='lazygit'
alias ca='cargo'
alias new='riverctl spawn "foot -D $(pwd)"'
alias wlc=wl-copy
alias wlp=wl-paste
alias im=swayimg
