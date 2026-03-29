set runtimepath+=~/.vim,~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

nnoremap <leader>p :echo getpid()<CR>

" load lua
lua require('init')
