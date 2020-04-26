# Functions
function start-ssh-agent {
  local sock_dir="${HOME}/.ssh/ssh_agent.sock"
  local pid_dir="${HOME}/.ssh/ssh_agent.pid"

  # Both pid and sock exists
  if [ -S "${sock_dir}" ] && [ -f "${pid_dir}" ]; then
    export SSH_AUTH_SOCK="${sock_dir}"
    export SSH_AGENT_PID="${pid_dir}"
  else
    echo "Starting ssh-agent"
    eval "$(ssh-agent -a ${sock_dir})"
    echo "${SSH_AGENT_PID}" > "${pid_dir}"
    ssh-add ~/.ssh/*_rsa
    trap "pkill ssh-agent && rm ${sock_dir} ${pid_dir}" EXIT
  fi
}

function start_vpn {
    local default_config_dir="/etc/openvpn/ipvanish-configs/"
    local default_ovpn_config="/etc/openvpn/client/default.ovpn"
    local region_string="${1:- }"
    local ovpn_config="$(ls "${default_config_dir}" | grep -i "${region_string}" | head -n 1)"
    ovpn_config="${ovpn_config:-${default_ovpn_config}}"
    echo "Using ovpn config file: \"${ovpn_config}\""
    sudo openvpn "${ovpn_config}"
    reset
}

function find_exc {
    local name=${1}
    shift
    local exclude=()
    for item in "$@"; do
        exclude+=("-not -path ${item}")
    done
    echo "find -name \"${name}\" -prune ${exclude[@]} -print"
    find -name "${name}" -prune ${exclude[@]} -print
}

start-ssh-agent

# Enviroment variables
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
alias vi="vim"
alias grep="grep -Ei"
alias ll="ls -ltrah --color=auto"
alias ls="ls --color=auto"
alias reboot="systemctl reboot"
alias poweroff="systemctl poweroff"
alias pup='yes | sudo pacman -Syyu'
alias cntp='sudo ntpdate ca.pool.ntp.org'
alias mount='sudo mount'
alias fuh='sudo "$BASH" -c "$(history -p !!)"'
alias g='git'
alias tsm="transmission-remote"

