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
export VIRTUALENV_WRAPPER_PATH="${HOME}/.local/bin/virtualenvwrapper.sh"
# Pull ghar files automatically
if which ghar > /dev/null ; then
  if [[ "$(ghar status)" =~ dirty ]]; then
  echo "New dotfile changes found, installing dotfiles"
  ghar pull > /dev/null
  ghar install > /dev/null
  fi
fi

FULL_NAME="Allen Ji"
EMAIL="ajixuan11@gmail.com"
GIT_BASE="${HOME}/Projects"

# Git config
if which git > /dev/null ; then
    git config --global user.name "${FULL_NAME}"
    git config --global user.email "${EMAIL}"
    git config --global credential.helper cache # Set git to use the credential memory cache
    git config --global credential.helper 'cache --timeout=3600' # Set the cache to timeout after 1 hour (setting is in seconds)
    git config --global core.editor vim
    git config --global push.default matching
fi

#git autocomplete
if [ -f ${HOME}/.git-completion.bash ]; then
  . ${HOME}/.git-completion.bash

  # Add git completion to aliases
  __git_complete g _git
fi


# Source additional scripts
# Run additional bashrc scipts
# Only execute additional .bashrc scripts if they are secure
while IFS= read -r -d '' script; do
  . "${script}"
done < <(find "${HOME}/.bashrc.d/" -type f -perm -g-xw,o-xw -user "${USER}" -print0)

# Source python virtualenvwrapper
[ -f "${VIRTUALENV_WRAPPER_PATH:-}" ] && . "${VIRTUALENV_WRAPPER_PATH}"

# Start ssh-agent
start-ssh-agent

#Color
if [[ $- == *i* ]]; then
  ucolor="\[$(tput setaf 2)\]"
  pcolor="\[$(tput setaf 6)\]"
  reset="\[$(tput sgr0)\]"
  PS1="${pcolor}[\@ ${ucolor}\\u@\\h${pcolor} \\w]\$ "
fi

#Aliases
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

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
