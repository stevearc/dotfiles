let g:python3_host_prog = expand("~/.envs/py3/bin/python")
let &rtp = &rtp . ',' . stdpath('data') . '-local'

" Profiling
" lua require('profile').instrument_autocmds()
nmap <f1> <cmd>lua if require'profile'.is_recording() then require'profile'.stop('profile.json') else require'profile'.start('*') end<cr>
nmap <f2> <cmd>lua require'plenary.profile'.start("profile.log", {flame = true})<cr>
nmap <f3> <cmd>lua require'plenary.profile'.stop()<cr>

let g:nerd_font = v:true
let g:debug_treesitter = 0
let g:null_ls = v:true
" Luasnip still has some issues https://github.com/L3MON4D3/LuaSnip/issues/206
let g:snippet_engine = 'luasnip'

" The syntax plugin was causing lag with multiple windows visible
let g:polyglot_disabled = ['sh']

" Minimal downsides and doesn't break file watchers
set backupcopy=yes

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1

" Space is leader
let mapleader = " "

" Allow backgrounding buffers without writing them, and remember marks/undo
" for backgrounded buffers
set hidden

" Remember 1000 commands and search history
set history=1000

" Use a recursive path (for :find)
set path=**

" When :find-ing, search for files with this suffix
set suffixesadd=.py,.pyx,.java,.c,.cpp,.rb,.html,.jinja2,.js,.jsx,.less,.css,.styl,.ts,.tsx,.go,.rs

" Make tab completion for files/buffers act like bash
set wildmenu
set wildmode=longest,list,full
set wildignore+=*.png,*.jpg,*.jpeg,*.gif,*.wav,*.aiff,*.dll,*.pdb,*.mdb,*.so,*.swp,*.zip,*.gz,*.bz2,*.meta,*.cache,*/\.git/*

" Make backspace work properly
set backspace=indent,eol,start

" Make searches case-sensitive only if they contain upper-case characters
set ignorecase
set smartcase

set previewheight=5

" Show the row, column of the cursor
set ruler

" Display incomplete commands
set showcmd

" When a bracket is inserted, briefly jump to the matching one
set showmatch

" Begin searching as soon as you start typing
set incsearch

" Magic preview for substitute and friends
set inccommand=nosplit

" Highlight search matches
set hls

" Make Y behave like I expect
nnoremap Y y$

" Highlight the cursor line only in the active window
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

set formatoptions=rqnlj

" Don't reopen buffers
set switchbuf=useopen,uselast

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

" CursorHold time default is 4s. Way too long
set updatetime=100

" Syntax highlighting
syntax enable
syntax on

" Return to last edit position when opening files
augroup SmartOpen
  au!
  autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") && expand('%:t') != 'COMMIT_EDITMSG' |
       \   exe "normal! g`\"" |
       \ endif
augroup END

" Set fileformat to Unix
set ff=unix

" Set encoding to UTF
set enc=utf-8

" Relative line numbers
se relativenumber
" Except for current line
set nu

" Enable use of mouse
set mouse=a

" Use 'g' flag by default with :s/foo/bar
set gdefault

" allow cursor to wrap to next/prev line
set whichwrap=h,l

filetype plugin on
filetype plugin indent on

" Set auto line wrapping options
set formatoptions=rqnolj

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

" Save jumps > 5 lines to the jumplist
" Jumps <= 5 respect line wraps
nnoremap <expr> j (v:count > 5 ? "m'" . v:count . 'j' : 'gj')
nnoremap <expr> k (v:count > 5 ? "m'" . v:count . 'k' : 'gk')

" Paste last text that was yanked, not deleted
nnoremap <leader>p "0p
nnoremap <leader>P "0P

" Move text in visual mode with J/K
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

augroup VCenterCursor
  au!
  au BufEnter,WinEnter,WinNew,VimResized *,*.*
        \ let &l:scrolloff=1+winheight(win_getid())/2
augroup END

let g:treesitter_languages = 'maintained'
let g:treesitter_languages_blacklist = ['supercollider']

" Start with folds open
se foldlevelstart=99
se foldlevel=99
" Disable fold column
se foldcolumn=0
function! CustomFold() abort
  let l:line = getline(v:foldstart)
  let l:idx = v:foldstart + 1
  while l:line =~ '^\s*@' || l:line =~ '^\s*$'
    let l:line = getline(l:idx)
    let l:idx += 1
  endwhile
  let l:icon = '▼'
  if g:nerd_font
    let l:icon = ''
  endif
  let l:padding = len(matchlist(l:line, '^\(\s*\)')[1])
  return printf('%s%s  %s   %d', repeat(' ', l:padding), l:icon, l:line, v:foldend - v:foldstart + 1)
endfunction
set fillchars=fold:\ 
set foldtext=CustomFold()

" Use my universal clipboard tool to copy with <leader>y
nnoremap <leader>y <cmd>call system('clip', @0)<CR>

" Map leader-r to do a global replace of a word
nnoremap <leader>r <cmd>%s/<C-R>=expand("<cword>")<CR>/<C-R>=expand("<cword>")<CR>

" Expand %% to current directory in command mode
cabbr <expr> %% expand('%:p:h')

aug Checkt
  au!
  au FocusGained * if getcmdwintype() == '' | checktime | endif
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
  autocmd CursorMovedI,InsertLeave * if pumvisible() == 0 && !&pvw|pclose|endif
augroup END

" BASH-style movement in insert mode
inoremap <C-a> <C-o>0
inoremap <C-e> <C-o>$

command! GitHistory Git! log -- %

let g:scnvim_no_mappings = 1
let g:scnvim_eval_flash_repeats = 1

let g:CheatSheetDoNotMap=1
let g:CheatDoNotReplaceKeywordPrg=1

" Netrw
" detail view
let g:netrw_liststyle = 1
" vsplit the preview
let g:netrw_preview = 1
" Show human-readable sizes
let g:netrw_sizestyle = "H"
" Preview splits right
let g:netrw_alto = 0
" Don't let Lexplore change the behavior of <cr>
let g:netrw_chgwin = 0

if has('win32')
  set shell=powershell
  set shellcmdflag=-command
  set shellquote=\"
  set shellxquote=
endif

" This lets our bash aliases know to use nvr instead of nvim
let $INSIDE_NVIM=1

if filereadable(expand('~/.local.vimrc'))
  source ~/.local.vimrc
endif
