alias vi="vim"
alias grep="grep -Ei"
alias ll="ls -ltrah --color=auto"
alias ls="ls --color=auto"
alias reboot="systemctl reboot"
alias poweroff="systemctl poweroff"

GOPATH=$HOME/go
PATH=$PATH:$HOME/Projects/ghar/bin
PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$GOPATH/bin

#Color
ucolor="\[$(tput setaf 2)\]"
pcolor="\e[36m"
reset="\[$(tput sgr0)\]"

PS1="${pcolor}[\@ ${ucolor}\\u@\\h${pcolor} \\W]\$ "
#Aliases
alias pup='yes | sudo pacman -Syyu'
alias cntp='sudo ntpdate ca.pool.ntp.org'
alias mount='sudo mount'
alias fuh='sudo "$BASH" -c "$(history -p !!)"'

function start-ssh-agent {
  local sock_dir="${HOME}/.ssh/ssh_agent.sock"
  local pid_dir="${HOME}/.ssh/ssh_agent.pid"

  # Both pid and sock exists
  if [ -f ${sock_dir} ] && [ -f ${pid_dir} ]; then
      export SSH_AUTH_SOCK="${sock_dir}"
      export SSH_AGENT_PID="${pid_dir}"
  # Only one of them exists
  elif [ -f ${sock_dir} ] || [  -f ${pid_dir} ]; then
      echo "Cleaning ssh dir.."
      rm "${HOME}/.ssh/ssh_agent.*"
      eval "$(ssh-agent -k -a ${sock_dir})"
      trap "pkill ssh-agent" EXIT
  # Both don't exist
  else
      echo "Starting ssh-agent"
      eval "$(ssh-agent -a ${sock_dir})"
      trap "pkill ssh-agent" EXIT
  fi
}
