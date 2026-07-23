alias vi="nvim"
alias vim="nvim"
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
alias gbrm='git branch | grep -vE "main|master" | xargs git branch -D'
alias goclean='go clean -cache -modcache -testcache -fuzzcache'
alias npmclean='npm cache clean --force'
alias dush='sudo du -h --max-depth=1 ./ | sort -h'
alias dbang='docker container prune && docker volume prune && docker system prune'
