#!/bin/bash
# handy functions on the command line

function start-ssh-agent {
  local sock="${HOME}/.ssh/ssh_agent.sock"
  local pid="${HOME}/.ssh/ssh_agent.pid"

  # Both pid and sock exists
  if [ -S "${sock}" ] && [ -f "${pid}" ] ; then
    export SSH_AUTH_SOCK="${sock}"
    export SSH_AGENT_PID="${pid}"

    if ssh-add ; then
      return 0
    fi
  fi

  rm "${sock}" "${pid}"
  echo "Starting ssh-agent"
  eval "$(ssh-agent -a ${sock})"
  echo "${SSH_AGENT_PID}" > "${pid}"
  ssh-add ~/.ssh/*_rsa
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

# Find Exclude
#   - find the first item while excluding everything that comes next
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
