#!/bin/bash

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Environment variables
GOPATH=$HOME/go
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$GOPATH/bin
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$PATH:$HOME/kubectl-plugins/"
export FZF_CTRL_R_OPTS='--sort --exact'
export FZF_DEFAULT_OPTS='--height 30%'
export WORKON_HOME="${HOME}/.virtualenvs"
export VIRTUALENV_WRAPPER_PATH="$HOME/.local/bin/virtualenvwrapper.sh"
export ANTHROPIC_FOUNDRY_RESOURCE=ia-foundry-coding-prod-eus2
export CLAUDE_CODE_USE_FOUNDRY=1
export AZURE_TOKEN_CREDENTIALS=dev
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Default github user and email
FULL_NAME="Allen Ji"
EMAIL="ajixuan11@gmail.com"
[ -f "${HOME}/.bash_local" ] && . "${HOME}/.bash_local"

# Git config
if which git > /dev/null ; then
    git config --global user.name "${FULL_NAME}"
    git config --global user.email "${EMAIL}"
fi

# git autocomplete
# Install .git-completion.bash from
# https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
# if does not exist in $HOME
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
#start-ssh-agent

#Color
if [[ $- == *i* ]]; then
  ucolor="\[$(tput setaf 2)\]"
  pcolor="\[$(tput setaf 6)\]"
  reset="\[$(tput sgr0)\]"
  PS1="${pcolor}[\@ ${ucolor}\\u@\\h${pcolor} \\w]\$ "
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Kubernetes
# Merge kube config files
for contextFile in `find "${HOME}/.kube" -type f -name "*.config"`
do
    export KUBECONFIG="$contextFile:$KUBECONFIG"
done

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
PATH=${PATH}:/home/aji/local_builds/usr/local/bin

export PATH=/home/aji/.opencode/bin:$PATH
. "$HOME/.cargo/env"
. "/home/aji/local_builds/usr/local/cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/home/aji/.opencode/bin:$PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
