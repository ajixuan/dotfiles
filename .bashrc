# Functions
function start-ssh-agent {
  local sock="${HOME}/.ssh/ssh_agent.sock"
  local pid="${HOME}/.ssh/ssh_agent.pid"

  # Both pid and sock exists
  if [ -S "${sock}" ] && [ -f "${pid}" ] ; then
    export SSH_AUTH_SOCK="${sock}"
    export SSH_AGENT_PID="${pid}"
  else
    echo "Starting ssh-agent"
    eval "$(ssh-agent -a ${sock})"
    echo "${SSH_AGENT_PID}" > "${pid}"
    ssh-add ~/.ssh/*_rsa
    trap "pkill ssh-agent && rm ${sock} ${pid}" EXIT
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
    [ $? -eq 0 ] && reset
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

####
# Docker functions
# Select a docker container to start and attach to
function da() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 --query="$1" | awk '{print $1}')

  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}

# Select a running docker container to stop
function ds() {
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker stop "$cid"
}

# Select a docker container to remove
function drm() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker rm "$cid"
}

start-ssh-agent

# Enviroment variables
GOPATH=$HOME/go
PATH=$PATH:$HOME/Projects/ghar/bin
PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$GOPATH/bin
export FZF_CTRL_R_OPTS='--sort --exact'
export FZF_DEFAULT_OPTS='--height 30%'
export WORKON_HOME="${HOME}/python-virtual-envs/"

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
alias mount='sudo mount'
alias fuh='sudo "$BASH" -c "$(history -p !!)"'
alias g='git'
alias tsm="transmission-remote"
alias fo='vim $(fzf)'

# Pull ghar files automatically
if which ghar ; then
    echo "Installing dotfiles with ghar"
    if [[ "$(ghar status)" =~ dirty ]]; then
        ghar pull > /dev/null
        ghar install > /dev/null
    fi
fi

. "${HOME}/.local/bin/virtualenvwrapper.sh"


#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
