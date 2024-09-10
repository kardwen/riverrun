# flatpak packages
alias signal='flatpak run org.signal.Signal > /dev/null &!'
alias drm='flatpak run org.mozilla.firefox > /dev/null &!'

alias firefox='firefox -p felix &!'
alias night='wlsunset -L 8 -l 52 &!'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

