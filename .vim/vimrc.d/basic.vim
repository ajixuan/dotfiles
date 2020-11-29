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
let mapleader = " "

" Fast saving and quiting
nmap <leader>w :w!<cr>
nmap <leader>q :q<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W w !sudo tee % > /dev/null

" Work around CVE-2019-12735.
set nomodeline

" Short cut for running ! commands
map <leader>e :tabnew<cr>:terminal<space>

" Fast saving
nmap <leader>w :w!<cr>

" Easy esc
inoremap ,. <esc>
vnoremap ,. <esc>

" vim mapped key timeout length
augroup timeoutlen
  autocmd!
  autocmd InsertEnter * set timeoutlen=100
  autocmd InsertLeave * set timeoutlen=1000
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 3 lines to the cursor - when moving vertically using j/k
set so=3

" Height of the command bar
set cmdheight=2

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

" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

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
highlight ExtraWhitespace ctermbg=1 guibg=1
highlight LspDiagnosticsError ctermfg=1
highlight LspDiagnosticsErrorSign ctermfg=1
highlight LspDiagnosticsWarning ctermfg=yellow
highlight LspDiagnosticsWarningSign ctermfg=yellow


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
"set tw=79

set ai "Auto indent
set si "Smart indent

" Line wrapping
set nowrap
noremap <Backspace> :set nowrap!<CR>

" Always split to right
set splitright
set splitbelow

" Toggle line numbers and fold column for easy copying
nnoremap <F2> :set number!<CR>:set relativenumber!<CR>:set foldcolumn=0<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Move to beginning and end of line
nmap H 0
nmap L $
vnoremap H 0
vnoremap L $

" Set 0 to go to first non-space character
map 0 ^

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
" <c-space> sends ^@ which is the <Nul> character
map <Nul> ?

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Quick resize windows
nnoremap <silent> <leader>l :exe "vertical resize " . (winwidth(0) * 2/5)<CR>
nnoremap <silent> <leader>h :exe "vertical resize " . (winwidth(0) * 5/3)<CR>
nnoremap <silent> <leader>j :exe "resize " . (winheight(0) * 2/5)<CR>
nnoremap <silent> <leader>k :exe "resize " . (winheight(0) * 5/3)<CR>

" VSP and SP
map <leader>\| :vsp<CR><c-p><CR>
map <leader>- :sp<CR><c-p><CR>

" Useful mappings for managing tabs
nmap <C-c> :tabclose<CR>
nmap <leader>tn :tabn<CR>
nmap <leader>tp :tabp<CR>
nmap <C-t> :tabnew<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
autocmd TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Quickly open a buffer for scribble
map <leader>b :vsp ~/buffer<cr>

" Quickly open a markdown buffer for scribble
map <leader>x :vsp ~/buffer.md<cr>

" Quickly open todo
map <leader>o :vsp ~/todo.md<cr>

" Auto window resize
augroup ReduceNoise
    autocmd!
    " Automatically resize active split to 85 width
    autocmd WinEnter * :call ResizeSplits()
augroup END

function! ResizeSplits()
    if &columns < 100 && winwidth('$') < 50
      set winwidth=85
      wincmd =
    else
      set winwidth=50
      wincmd =
    endif
endfunction

" Maximize current pane
nnoremap <leader>m :call MaximizeToggle()<cr>
function! MaximizeToggle()
  if exists("s:maximize_session")
    exec "source " . s:maximize_session
    call delete(s:maximize_session)
    unlet s:maximize_session
    let &hidden=s:maximize_hidden_save
    unlet s:maximize_hidden_save
  else
    let s:maximize_hidden_save = &hidden
    let s:maximize_session = tempname()
    set hidden
    exec "mksession! " . s:maximize_session
    only
  endif
endfunction


""""""""""""""""""""""""""""
" => Editing
""""""""""""""""""""""""""""

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
vnoremap <C-n> :nohl<CR>
inoremap <C-n> <esc>:nohl<CR>i

" Retab lines
" noremap tt :call ResizeTabs()<CR>

" Yank to clipboard-
vnoremap <leader>y "*y<CR>

" Edit vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" Fast quotes
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
vnoremap <leader>" <esc>`<i"<esc>`>la"<esc>
vnoremap <leader>' <esc>`<i'<esc>`>la'<esc>

" Replace
nnoremap <leader>s :%s/
vnoremap <leader>s :s/

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Auto commands
" au = autocmd
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup general
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
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -nargs=* T 20split | terminal <args>
command! -nargs=* VT vsplit | terminal <args>
tnoremap <A-,> <C-\><C-n>

"augroup terminal
"  autocmd! TermOpen * startinsert
"augroup END

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

