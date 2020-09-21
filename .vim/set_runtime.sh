#!/bin/bash

# vars
script_dir="$(dirname ${BASH_SOURCE[0]})"
pathogen_url='https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim'
nerdtree_url='https://github.com/preservim/nerdtree.git'
fzf_url='https://github.com/junegunn/fzf.git'
ctags_url='https://github.com/universal-ctags/ctags.git'

mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/bundle"
mkdir -p "${script_dir}/syntax"

# Get Pathogen
curl -LSso "${script_dir}/autoload/pathogen.vim" "${pathogen_url}"

# Nerd Tree
git clone "${nerdtree_url}" "${script_dir}/bundle/nerdtree"

# fzf
git clone "${fzf_url}" "${script_dir}/bundle/fzf"

# ctags
if ! which ctags > /dev/null ; then
  git clone "${ctags_url}" "${HOME}/tmp"
  ( cd "${HOME}/tmp" && \
      "./autogen.sh" && \
      "./configure" --prefix="${HOME}" && \
      make && \
      make install )
fi
