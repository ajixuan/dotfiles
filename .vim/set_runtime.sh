#!/bin/bash
set -e

# vars
build=${BUILD:-true}
script_dir="$(dirname ${BASH_SOURCE[0]})"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo "im a snowman ☃"
mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/plugged"
mkdir -p "${script_dir}/syntax"

# Get Plug
if [ ! -f "${script_dir}/autoload/plug.vim" ]; then
  curls "${plug_url}" "${script_dir}/autoload/plug.vim"
fi

if ${build}; then
  . "${script_dir}/build_env.sh"
  BUILD_DIR="${HOME}/tmp/local" . "${script_dir}/build.sh"
fi
