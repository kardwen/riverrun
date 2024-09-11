# flatpak packages
alias signal='flatpak run org.signal.Signal > /dev/null &!'
alias drm='flatpak run org.mozilla.firefox > /dev/null &!'

alias firefox='firefox -p felix &!'
alias night='wlsunset -L 8 -l 52 &!'

# coreutils color mappings
eval $(dircolors -p | perl -pe 's/^((CAP|S[ET]|O[TR]|M|E)\w+).*/$1 00/' | dircolors -)
alias ls='ls --color=auto'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
