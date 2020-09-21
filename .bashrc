#!/bin/bash
# Enviroment variables
GOPATH=$HOME/go
PATH=$PATH:$HOME/Projects/ghar/bin
PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$HOME/bin
PATH=$PATH:$GOPATH/bin
export FZF_CTRL_R_OPTS='--sort --exact'
export FZF_DEFAULT_OPTS='--height 30%'
export WORKON_HOME="${HOME}/python-virtual-envs/"

# Pull ghar files automatically
if which ghar > /dev/null ; then
  if [[ "$(ghar status)" =~ dirty ]]; then
  echo "New dotfile changes found, installing dotfiles"
  ghar pull > /dev/null
  ghar install > /dev/null
  fi
fi

# Import Functions
. "${HOME}/.bashrc.d/utils.sh"

# Start ssh-agent
start-ssh-agent

#Color
ucolor="\[$(tput setaf 2)\]"
pcolor="\[$(tput setaf 6)\]"
reset="\[$(tput sgr0)\]"
PS1="${pcolor}[\@ ${ucolor}\\u@\\h${pcolor} \\W]\$ "

#Aliases
alias vi="vim"
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
alias fo='vim $(fzf)'

. "${HOME}/.local/bin/virtualenvwrapper.sh"

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
