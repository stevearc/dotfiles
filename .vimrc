let g:ale_emit_conflict_warnings = 0
" Load plugins from the bundle directory
call pathogen#infect()
call pathogen#helptags()

" Use this file to set neovim python paths so it works with virtualenvs
" It will look like:
" let g:python_host_prog="/usr/bin/python"
" let g:python3_host_prog="/usr/bin/python3"
if filereadable(expand('~/.nvim_python'))
  source ~/.nvim_python
endif

" Use Vim settings, rather than Vi
set nocompatible

" Allow backgrounding buffers without writing them, and remember marks/undo
" for backgrounded buffers
set hidden

" Remember 1000 commands and search history
set history=1000

" Use a recursive path (for :find)
set path=**

" When :find-ing, search for files with this suffix
set suffixesadd=.py,.pyx,.java,.c,.cpp,.rb,.html,.jinja2,.js,.jsx,.less,.css,.styl

" Make tab completion for files/buffers act like bash
set wildmenu
set wildmode=full
set wildignore+=*.png,*.jpg,*.jpeg,*.gif,*.wav,*.dll,*.meta

" Make searches case-sensitive only if they contain upper-case characters
set smartcase

" Autocompletion should only insert text up to the longest common substring of
" all matches.
set completeopt+=longest

" Show the row, column of the cursor
set ruler

" Display incomplete commands
set showcmd

" When a bracket is inserted, briefly jump to the matching one
set showmatch

" Begin searching as soon as you start typing
set incsearch

" Highlight search matches
set hls

" Highlight the cursor line only in the active window
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

set formatoptions=rqnlj

" Don't reopen buffers
set switchbuf=useopen

" Always show tab line
set showtabline=2

" Size of tabs
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set laststatus=2

" Line width of 80
set tw=80

" Trim trailing whitespace on save
function! TrimTrailingWhitespace()
  :%s/\s\+$//ge
endfunction
command! TrimTrailingWhitespace :call TrimTrailingWhitespace()
" Note js & json excluded because we use Neoformat
aug TrimWhitespace
  au!
  autocmd BufWrite *.coffee,*.cjsx,*.jsx,*.html,*.jinja2,*.j2,*.css,*.less,*.styl,*.py,*.rb,*.go,*.ino,*.c,*.cpp,*.h,*.sh if ! &bin | silent! call TrimTrailingWhitespace() | endif
aug END


" SOLARIZED
syntax enable
syntax on
set t_Co=256
let g:solarized_termcolors=256
let g:solarized_contrast="high"
let g:solarized_visibility="high"
set background=light
colorscheme solarized

" Return to last edit position when opening files
augroup SmartOpen
  au!
  autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") |
       \   exe "normal! g`\"" |
       \ endif
augroup END

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
map N Nzz
map n nzz

" Set fileformat to Unix
set ff=unix

" Set encoding to UTF
set enc=utf-8

" Line numbers on
set nu

" Enable use of mouse
set mouse=a

" Use 'g' flag by default with :s/foo/bar
set gdefault

" allow cursor to wrap to next/prev line
set whichwrap=h,l

filetype plugin on
filetype plugin indent on

" Set auto line wrapping options (overwrites plugins)
augroup LineWrap
  au!
  au FileType * setlocal formatoptions=rqnlj
augroup end

" Add bash shortcuts for command line
:cnoremap <C-a>  <Home>
:cnoremap <C-b>  <Left>
:cnoremap <C-f>  <Right>
:cnoremap <C-d>  <Delete>
:cnoremap <M-b>  <S-Left>
:cnoremap <M-f>  <S-Right>
:cnoremap <M-d>  <S-right><Delete>
:cnoremap <Esc>b <S-Left>
:cnoremap <Esc>f <S-Right>
:cnoremap <Esc>d <S-right><Delete>
:cnoremap <C-g>  <C-c>

source ~/.vim/config/ctrlp.vim
source ~/.vim/config/quickfix.vim
source ~/.vim/config/folding.vim
source ~/.vim/config/deoplete.vim
source ~/.vim/config/lsp.vim
source ~/.vim/config/smartrun.vim
source ~/.vim/config/tabs.vim
source ~/.vim/config/windows.vim
source ~/.vim/config/terminal.vim
source ~/.vim/config/ultisnips.vim
source ~/.vim/config/clevertab.vim
source ~/.vim/config/easymotion.vim
source ~/.vim/config/grep.vim
source ~/.vim/config/session.vim
source ~/.vim/config/syntastic.vim
source ~/.vim/config/ale.vim
source ~/.vim/config/neoformat.vim

" Function to rename the current file
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
map <leader>n :call RenameFile()<cr>

" Function to duplicate the current file
function! DuplicateFile()
    let old_name = expand('%')
    let new_name = input('Duplicate to: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        redraw!
    endif
endfunction
map <leader>m :call DuplicateFile()<cr>

" Map leader-r to do a global replace of a word
nmap <leader>r :%s/<C-R>=expand("<cword>")<CR>/<C-R>=expand("<cword>")<CR>

" Expand %% to current directory in command mode
cabbr <expr> %% expand('%:p:h')

" Keep cursor in the vertical center of the editor
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap G Gzz
nnoremap <C-o> <C-o>zz
nnoremap <C-i> <C-i>zz

" j and k navigate line-wraps in a sane way (also vertical center)
nnoremap j gjzz
nnoremap k gkzz
vnoremap j gjzz
vnoremap k gkzz

aug Checkt
  au!
  au FocusGained * checktime
aug END

" Enter paste mode with <C-v> in insert mode
imap <C-v> <C-o>:set paste<CR>
" Exit paste mode when leaving insert mode
aug Unpaste
  au!
  au InsertLeave * set nopaste
aug END

" Close the scratch preview automatically
augroup CloseScratch
  au!
  autocmd CursorMovedI,InsertLeave * if pumvisible() == 0|pclose|endif
augroup END

" Useful for removing whitespace after abbreviations
function! Eatchar(pat)
  let c = nr2char(getchar(0))
  return (c =~ a:pat) ? '' : c
endfunc

" BASH-style movement in insert mode
inoremap <C-a> <C-o>0
inoremap <C-e> <C-o>$

nmap <C-w><C-b> :tabedit %<CR>

nmap <leader>gs :Gstatus<CR>
nmap <leader>gh :Git! log -- %<CR>

" Use cjsx to build because it's a superset of coffeescript
if executable('cjsx')
  let coffee_compiler = exepath('cjsx')
endif

aug Colorize
  au!
  au BufReadPost * command! -buffer -bar Colorize call css_color#init('css', 'extended', 'cssFunction')
aug END

" Shortcut for clipper
nnoremap <leader>y :call system('nc localhost 8377', @0)<CR>

" Omnisharp
let g:Omnisharp_start_server = 0

" Cmdr
function! Cmdr(cmd)
  call system('nc localhost 8585', a:cmd)
endfunction

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1

function! ProseMode()
  setlocal spell noci nosi noai nolist noshowmode noshowcmd nonu
  setlocal complete+=s
  setlocal formatoptions+=t
endfunction

command! ProseMode call ProseMode()
