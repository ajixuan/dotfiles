#!/bin/bash
set -e

# vars
script_dir="$(dirname ${BASH_SOURCE[0]})"
plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
ctags_url='https://github.com/universal-ctags/ctags.git'
rust_url='https://sh.rustup.rs'
ripgrep_url='https://github.com/BurntSushi/ripgrep'

mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/plugged"
mkdir -p "${script_dir}/syntax"

# Get Plug
curl -fLo "${script_dir}/autoload/plug.vim" "${plug_url}"

# build ripgrep
if ! which rg > /dev/null ; then
  if ! which cargo > /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    sed '/^\# Environment variables/a export PATH=\$PATH:\$HOME\/.cargo\/bin' ~/.bashrc
  fi
  git clone "${ripgrep_url}" "${HOME}/tmp/ripgrep"
  ( cd "${HOME}/tmp"                   && \
    cargo build --release              && \
    cp ./target/release/rg "${HOME}/bin" )
fi

# ctags
if ! which ctags > /dev/null ; then
  git clone "${ctags_url}" "${HOME}/tmp/ctags"
  ( cd "${HOME}/tmp" && \
      "./autogen.sh" && \
      "./configure" --prefix="${HOME}" && \
      make && \
      make install )
fi

