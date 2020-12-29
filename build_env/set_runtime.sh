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
work_dir="${script_dir}/../"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
rust_analyzer_url='https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux'

echo "im a snowman ☃"
mkdir -p "${work_dir}/.vim/autoload"
mkdir -p "${work_dir}/.vim/plugged"
mkdir -p "${work_dir}/.vim/syntax"

# Get Plug
if [ ! -f "${work_dir}/autoload/plug.vim" ]; then
  curl -fsSL "${plug_url}" --create-dirs -o "${work_dir}/.vim/autoload/plug.vim"
fi

# rust analyzer
if [ ! -f "${HOME}/bin/rust-analyser" ]; then
  curl -fsSL "${rust_analyzer_url}" --create-dirs -o "${HOME}/bin/rust-analyzer"
  chmod +x "${HOME}/bin/rust-analyzer"
fi

if ${build}; then
  echo "Building tools"
  . "${script_dir}/build.sh"
fi
