alias vi="nvim"
alias grep="grep -Ei"
alias ll="ls -ltrah --color=auto"
alias ls="ls --color=auto"
alias reboot="systemctl reboot"
alias poweroff="systemctl poweroff"
alias pup='yes | sudo pacman -Syyu'
alias mount='sudo mount'
alias fuh='sudo "$BASH" -c "$(history -p !!)"'
alias g='git'
alias tsm="transmission-remote"
alias k="kubectl"
alias dang='docker rmi $(docker images -f "dangling=true" -q)'
alias note="grep $(date +%d%m%Y) ${HOME}/ajichangelog.md || echo $(date +%d%m%Y) >> ${HOME}/ajichangelog.md && vi ${HOME}/ajichangelog.md"
alias todo="grep $(date +%d%m%Y) ${HOME}/todo.md || echo $(date +%d%m%Y) >> ${HOME}/todo.md && vi ${HOME}/todo.md"
alias dotfiles='/usr/bin/git -C "${HOME}/.dotfiles/"'
