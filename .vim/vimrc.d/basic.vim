" Reminder
" ctrl-o prev cursor
" ctrl-i next cursor

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W w !sudo tee % > /dev/null

" Work around CVE-2019-12735.
set nomodeline

" Short cut for running ! commands
map <leader>e :!

" Fast saving
nmap <leader>w :w!<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 3 lines to the cursor - when moving vertically using j/k
set so=3

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
set bs=2

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" line numbers
set number relativenumber
set numberwidth=1
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set number relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set number norelativenumber
augroup END


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors, line visuals and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable custom syntax highlighting
" syntax on will overwite custom configs and use default
syntax enable

colorscheme desert
set background=dark

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Show color column at line 80
set colorcolumn=80

" Color groups
highlight ColorColumn ctermbg=blue
highlight ExtraWhitespace ctermbg=red guibg=red


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=79

set ai "Auto indent
set si "Smart indent
set nowrap


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around, tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
" <c-space> sends ^@ which is the <Nul> character
map <space> /
map <Nul> ?

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Quick resize windows
nnoremap <silent> <leader>l :exe "vertical resize " . (winwidth(0) * 2/3)<CR>
nnoremap <silent> <leader>h :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <leader>j :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <leader>k :exe "resize " . (winheight(0) * 2/3)<CR>

" VSP and SP
map <leader>v :vsp<CR>
map <leader>s :sp<CR>

" Useful mappings for managing tabs
nmap <C-c> :tabclose<CR>
nmap <leader>tn :tabn<CR>
nmap <leader>tp :tabp<CR>
nmap <C-t> :tabnew<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Set 0 to go to first non-space character
map 0 ^

" Always split to right
set splitright


""""""""""""""""""""""""""""
" => Editing
""""""""""""""""""""""""""""
" Toggle line numbers and fold column for easy copying
nnoremap <F2> :set number!<CR>:set relativenumber!<CR>:set foldcolumn=0<CR>

" Better copy & paste
" When you want to paste large blocks of code into vim, press F2 before you
" paste. At the bottom you should see ``-- INSERT (paste) --``.
set pastetoggle=<F2>
set clipboard=unnamed

" easier moving of code blocks
" better indentation
vnoremap < <gv
vnoremap > >gv

" map sort function to a Ctrl-Down
vnoremap <C-Down> :sort<CR>

" Bind nohl
" Removes highlight of your last search
noremap <C-n> :nohl<CR>
"vnoremap <C-n> :nohl<CR>
"inoremap <C-n> :nohl<CR>

" Retab lines
" noremap tt :call ResizeTabs()<CR>

" Yank to clipboard-
vnoremap <leader>y ",y<CR>


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickly open a buffer for scribble
map <leader>b :vsp ~/buffer<cr>

" Quickly open a markdown buffer for scribble
map <leader>x :vsp ~/buffer.md<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Auto commands
" au = autocmd
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("autocmd")
  " Auto reload .vimrc or *.vim ext files
  " ! mark will remove all autocmds before loading this one
  " This way autocmds won't stack on top from prev loads
  autocmd! BufWritePost .vimrc,*.vim source %

  " Show trailing whitespace
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/

  " Clean traling whitespace
  autocmd BufWritePre * :call CleanExtraSpaces()

  " Retab files
  "autocmd BufWritePre * :call ResizeTabs()
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
  if &paste
  return 'PASTE MODE  '
  endif
  return ''
endfunction

" Delete trailing white space on save, useful for some filetypes ;)
fun! CleanExtraSpaces()
  let save_cursor = getpos(".")
  let old_query = getreg('/')
  silent! %s/\s\+$//e
  call setpos('.', save_cursor)
  call setreg('/', old_query)
endfun

fun! ResizeTabs()
  let save_cursor = getpos(".")
  %s/^\s\{4}/  /e
  call setpos('.', save_cursor)
endfun

