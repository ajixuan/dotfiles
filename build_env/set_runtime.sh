#!/bin/bash
set -e


# Arch based packages
# Composite manager: xcompmgr
#   - pacman -S xcompmgr
#   - AUR transset-df
# Terminal: alacritty

# vars
export build=${BUILD:-true}
export BUILD_DIR=${BUILD_DIR:-${HOME}/tmp/local}
script_dir="$(dirname ${BASH_SOURCE[0]})"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "im a snowman ☃"
mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/plugged"
mkdir -p "${script_dir}/syntax"

# Get Plug
if [ ! -f "${script_dir}/autoload/plug.vim" ]; then
  curl -fsSL "${plug_url}" --create-dirs -o "${script_dir}/autoload/plug.vim"
fi

if ${build}; then
  echo "Building tools"
  . "${script_dir}/build.sh"
fi
