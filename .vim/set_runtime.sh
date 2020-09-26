#!/bin/bash

# vars
script_dir="$(dirname ${BASH_SOURCE[0]})"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
ctags_url='https://github.com/universal-ctags/ctags.git'

mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/plugged"
mkdir -p "${script_dir}/syntax"

# Get Plug
curl -fLo "${script_dir}/autoload/plug.vim" "${plug_url}"

# ctags
if ! which ctags > /dev/null ; then
  git clone "${ctags_url}" "${HOME}/tmp"
  ( cd "${HOME}/tmp" && \
      "./autogen.sh" && \
      "./configure" --prefix="${HOME}" && \
      make && \
      make install )
fi
