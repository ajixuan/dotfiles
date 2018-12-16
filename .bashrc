alias vi="vim"
alias grep="grep -Ei"
alias ll="ls -ltrah --color=auto"
alias ls="ls --color=auto"
alias reboot="systemctl reboot"
alias poweroff="systemctl poweroff"

PATH=$PATH:/home/aji/Projects/ghar/bin
PATH=$PATH:/home/aji/.local/bin

#Color
ucolor="\[$(tput setaf 2)\]"
pcolor="\e[36m"
reset="\[$(tput sgr0)\]"

PS1="${pcolor}[\@ ${ucolor}\\u@\\h${pcolor} \\W]\$ "

