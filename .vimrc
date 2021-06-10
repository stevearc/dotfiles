" Load plugins from the bundle directory
call pathogen#infect()
call pathogen#helptags()

let g:python3_host_prog = expand("~/.envs/py3/bin/python")

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
set wildmode=longest,list,full
set wildignore+=*.png,*.jpg,*.jpeg,*.gif,*.wav,*.aiff,*.dll,*.pdb,*.mdb,*.so,*.swp,*.zip,*.gz,*.bz2,*.meta,*.cache,*/\.git/*

" Make backspace work properly
set backspace=indent,eol,start

" Make searches case-sensitive only if they contain upper-case characters
set ignorecase
set smartcase

set completeopt=menuone,noselect
set shortmess+=c
set previewheight=5

" Show the row, column of the cursor
set ruler

" Display incomplete commands
set showcmd

" When a bracket is inserted, briefly jump to the matching one
" Disabling this for now b/c causing hang & crash in WSL
" set showmatch
set noshowmatch

" Begin searching as soon as you start typing
set incsearch

" Magic preview for substitute and friends
set inccommand=nosplit

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

" CursorHold time default is 4s. Way too long
set updatetime=100

" Syntax highlighting
syntax enable
syntax on

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
map N Nzvzz
map n nzvzz

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

let g:old_centering = 0

if g:old_centering
  " Keep cursor in the vertical center of the editor
  nnoremap <C-d> <C-d>zz
  nnoremap <C-u> <C-u>zz
  nnoremap G Gzz
  nnoremap <C-o> <C-o>zz
  nnoremap <C-i> <C-i>zz
  nnoremap { {zz
  nnoremap } }zz

  " j and k navigate line-wraps in a sane way (also vertical center)
  nnoremap j gjzz
  nnoremap k gkzz
  vnoremap j gjzz
  vnoremap k gkzz
else
  nnoremap j gj
  nnoremap k gk
  vnoremap j gj
  vnoremap k gk

  augroup VCenterCursor
    au!
    au BufEnter,WinEnter,WinNew,VimResized *,*.*
          \ let &scrolloff=1+winheight(win_getid())/2
  augroup END
end

let g:vsnip_snippet_dirs = [
      \ $HOME.'/.vim/vsnip',
      \ $HOME.'/.config/nvim/vsnip',
      \ ]

function! SmartVisual(visualmode) abort
  let line = getline('.')
  let positions = filter([
        \ stridx(line, '('),
        \ stridx(line, '['),
        \ stridx(line, '{'),
        \ stridx(line, ')'),
        \ stridx(line, ']'),
        \ stridx(line, '}'),
        \ ], 'v:val > -1')
  if empty(positions)
    return
  endif
  let idx = min(positions)
  let pos = getpos('.')
  call setpos('.', [pos[0], pos[1], idx + 1, pos[3]])
  exec 'normal! ' . a:visualmode . '%'
endfunction
nmap <leader>v :call SmartVisual('v')<CR>
nmap <leader>V :call SmartVisual('V')<CR>

" Smart tab behavior
let g:ulti_expand_or_jump_res = 0 "default value, just set once
let g:autocomplete_cmd = "\<C-x>\<C-o>"
function! CleverTab() abort
  if vsnip#available(1)
    if pumvisible()
      call feedkeys("\<C-x>\<C-x>")
    endif
    call Vsnip_expand_or_jump()
    return ''
  elseif pumvisible()
    return "\<C-n>"
  elseif strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"
  elseif &omnifunc == ''
    return "\<C-p>"
  else
    return g:autocomplete_cmd
  endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>

function! Vsnip_expand_or_jump()
  let l:ctx = {}
  function! l:ctx.callback() abort
    let l:context = vsnip#get_context()
    let l:session = vsnip#get_session()
    if !empty(l:context)
      call vsnip#expand()
    elseif !empty(l:session) && l:session.jumpable(1)
      call l:session.jump(1)
    endif
  endfunction

  " This is needed to keep normal-mode during 0ms to prevent CompleteDone handling by LSP Client.
  let l:maybe_complete_done = !empty(v:completed_item) && !empty(v:completed_item.user_data)
  if l:maybe_complete_done
    call timer_start(0, { -> l:ctx.callback() })
  else
    call l:ctx.callback()
  endif
endfunction
function! Vsnip_jump(direction) abort
  let l:session = vsnip#get_session()
  if !empty(l:session) && l:session.jumpable(a:direction)
    call l:session.jump(a:direction)
  endif
endfunction
function! ForwardsInInsert() abort
  if vsnip#jumpable(1)
    call Vsnip_jump(1)
  elseif g:completion_plugin == 'completion-nvim'
    lua require'completion'.nextSource()
  endif
endfunction
function! BackwardsInInsert() abort
  if vsnip#jumpable(-1)
    call Vsnip_jump(-1)
  elseif g:completion_plugin == 'completion-nvim'
    lua require'completion'.prevSource()
  endif
endfunction

" Snippets
let g:vsnip_filetypes = {}
let g:vsnip_filetypes.javascriptreact = ['javascript']
let g:vsnip_filetypes.typescriptreact = ['typescript']
smap <Tab> <Plug>(vsnip-jump-next)
xmap <Tab> <Plug>(vsnip-cut-text)
smap <C-h> <Plug>(vsnip-jump-prev)
imap <C-h> <cmd>call BackwardsInInsert()<cr>
smap <C-l> <Plug>(vsnip-jump-next)
imap <C-l> <cmd>call ForwardsInInsert()<cr>
" Clear Vsnip session when we switch to normal mode.
aug ClearVsnipSession
  au!
  " Can't use InsertLeave here because that fires when we go to select mode
  au CursorHold * call vsnip#deactivate()
aug END

" Treesitter
let g:debug_treesitter = 0
let g:treesitter_languages = [
      \ "bash", "c", "c_sharp", "cpp", "go", "graphql", "java", "json",
      \ "kotlin", "latex", "lua", "python", "rst", "ruby", "rust", "toml",
      \]

" Start with folds open
se foldlevelstart=99
se foldlevel=99
" Disable fold column
se foldcolumn=0

" Use my universal clipboard tool to copy with <leader>y
nnoremap <leader>y :call system('clip', @0)<CR>

" Map leader-r to do a global replace of a word
nmap <leader>r :%s/<C-R>=expand("<cword>")<CR>/<C-R>=expand("<cword>")<CR>

" Expand %% to current directory in command mode
cabbr <expr> %% expand('%:p:h')

" Map F5 to reload buffers from disk
nnoremap <F5> :silent checktime<CR>

" Helpful delete/change into blackhole buffer
nnoremap <leader>d "_d
nnoremap <leader>c "_c
vnoremap <leader>d "_d
vnoremap <leader>c "_c

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
  autocmd CursorMovedI,InsertLeave * if pumvisible() == 0 && !&pvw|pclose|endif
augroup END

" Useful for removing whitespace after abbreviations
function! Eatchar(pat)
  let c = nr2char(getchar(0))
  return (c =~ a:pat) ? '' : c
endfunc

" BASH-style movement in insert mode
inoremap <C-a> <C-o>0
inoremap <C-e> <C-o>$

command! GitHistory Git! log -- %

" Fix * and # behavior to respect smartcase
nnoremap <silent> * :let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=1<CR>nzz
nnoremap <silent> # :let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=0<CR>nzz
nnoremap <silent> g* :let @/='\v'.expand('<cword>')<CR>:let v:searchforward=1<CR>nzz
nnoremap <silent> g# :let @/='\v'.expand('<cword>')<CR>:let v:searchforward=0<CR>nzz

" Defx mappings
nnoremap <silent> - :Defx `expand('%:p:h')` -search=`expand('%:p')` -vertical-preview -preview-height=100 -preview-width=80<CR>
nnoremap <leader>w :Defx -split=vertical -winwidth=50 -direction=topleft -toggle<CR>
nnoremap <leader>W :Defx `expand('%:p:h')` -search=`expand('%:p')` -split=vertical -winwidth=50 -direction=topleft -toggle<CR>

" Telescope mappings
nnoremap <leader>t <cmd>lua require('stevearc.telescope').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>b <cmd>lua require('stevearc.telescope').buffers()<cr>

let g:scnvim_no_mappings = 1
let g:scnvim_eval_flash_repeats = 1

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

se stl=%!statusline#StatusLine()

let g:completion_plugin = 'compe'
lua require 'init_lua'
