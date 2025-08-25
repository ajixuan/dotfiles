set runtimepath+=~/.vim,~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" load lua
lua require('init')
