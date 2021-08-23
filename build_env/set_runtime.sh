#!/bin/bash
set -e

# A script to setup my work environment

# Arch based packages
# Composite manager: xcompmgr
#   - pacman -S xcompmgr
#   - AUR transset-df
# Terminal: alacritty
# floating windows: alnj
#   - wmctrl
#   - xdotool

# vars
script_dir="$(dirname ${BASH_SOURCE[0]})"
work_dir="${WORK_DIR:-${HOME}}"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
ghar_url='https://github.com/philips/ghar.git'

echo "im a snowman ☃"
mkdir -p "${work_dir}/.vim/autoload"
mkdir -p "${work_dir}/.vim/plugged"
mkdir -p "${work_dir}/.vim/syntax"

if ${build}; then
  echo "Building tools"
  . "${script_dir}/build.sh"
fi

# Get Plug
if [ ! -f "${work_dir}/autoload/plug.vim" ]; then
  echo "Download plug"
  curl -fsSL "${plug_url}" --create-dirs -o "${work_dir}/.vim/autoload/plug.vim"
fi

# Install ghar
if [ ! -f "${work_dir}/bin/ghar" ]; then
  echo "Download ghar"
  git_cl "${ghar_url}" "${work_dir}/ghar"
  ln -s "${work_dir}/ghar/bin/ghar" "${work_dir}/bin/ghar"
fi

# Install dotfiles
echo "Installing dotfiles"
ghar add "$(git remote get-url origin)" mydotfiles
ghar install mydotfiles
