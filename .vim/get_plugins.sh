#!/bin/bash
set -e

# vars
script_dir="$(dirname ${BASH_SOURCE[0]})"
pathogen_url='https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim'
nerdtree_url='https://github.com/preservim/nerdtree.git'

mkdir -p "${script_dir}/autoload"
mkdir -p "${script_dir}/bundle"

# Get Pathogen
curl -LSso "${script_dir}/autoload/pathogen.vim" "${pathogen_url}"

# Nerd Tree
git clone "${nerdtree_url}" "${script_dir}/bundle/nerdtree"

