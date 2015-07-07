" Load plugins from the bundle directory
call pathogen#infect()
call pathogen#helptags()

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
set suffixesadd=.py,.pyx,.java,.c,.cpp,.rb,.html,.jinja2,.js,.less,.css,.styl

" Make tab completion for files/buffers act like bash
set wildmenu
set wildmode=full
set wildignore+=*.png,*.jpg,*.jpeg,*.gif

" Make searches case-sensitive only if they contain upper-case characters
set ignorecase
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

" Auto-indent on line wrap
set showbreak=--->

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

set tw=80
" Use longer lines in coffeescript because that's how we do at Artillery
au FileType coffee setlocal tw=100

" Use 4-space tabs for certain file types
au FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4
" Trim trailing whitespace on save
autocmd BufWrite *.json,*.js,*.coffee,*.cjsx,*.jsx,*.html,*.jinja2,*.j2,*.css,*.less,*.styl,*.py,*.rb,*.go,*.ino,*.c,*.cpp,*.h,*.sh if ! &bin | silent! %s/\s\+$//ge | endif

" use the :help command for 'K' in .vim files
autocmd FileType vim set keywordprg=":help"

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
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

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
au FileType * setlocal formatoptions=rqnlj

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

" Execute current file
function! SmartRun()
    :w
    :silent !clear
    if match(expand("%"), '.py$') != -1
        exec ":!python " . @%
    elseif match(expand("%"), '.sh$') != -1
        exec ":!bash " . @%
    elseif match(expand("%"), '.rb$') != -1
        exec ":!ruby " . @%
    elseif match(expand("%"), '.go$') != -1
        GoRun
    elseif match(expand("%"), '.coffee$') != -1
        exec ":!coffee " . @%
    end
endfunction
map <leader>e :call SmartRun()<cr>

" Map leader-r to do a global replace of a word
map <leader>r :%s/<C-R>=expand("<cword>")<CR>/<C-R>=expand("<cword>")<CR>

" Fast tab navigation
map <leader>1 1gt
map <leader>2 2gt
map <leader>3 3gt
map <leader>4 4gt
map <leader>5 5gt
map <leader>6 6gt
map <leader>7 7gt
map <leader>8 8gt
map <leader>9 9gt

" Window size settings
set winwidth=88 " minimum width of current window (includes gutter)
set winheight=20 " minimal height of current window
let g:wequality = 1
function! ResizeWindows()
    if( g:wequality == 1 )
        exe ":normal \<C-w>="
    endif
endfunction
function! ToggleWinEqual()
    if( g:wequality == 0 )
        let g:wequality = 1
    else
        let g:wequality = 0
    endif
endfunction
augroup WinWidth
  au!
  " Keep window sizes roughly equal
  au VimEnter,WinEnter,BufWinEnter * :call ResizeWindows()
augroup END
nmap <C-w>+ :call ToggleWinEqual()<CR>

" Go to next/prev result with <Ctrl> + n/p
nmap <silent> <C-N> :cn<CR>zv
nmap <silent> <C-P> :cp<CR>zv

" Keep cursor in the vertical center of the editor
noremap <C-d> <C-d>zz
noremap <C-u> <C-u>zz
noremap G Gzz
noremap <C-o> <C-o>zz
noremap <C-i> <C-i>zz

" j and k navigate line-wraps in a sane way (also vertical center)
noremap j gjzz
noremap k gkzz

" Remap q: to just go to commandline.  To open the commandline window,
" do <C-r> from the commandline
:set cedit=<C-r>
nnoremap q: :

" Navigate tabs with <S-Tab>
map <S-Tab> gt

" Enter paste mode with <leader>p
nmap <leader>p :set paste<CR>a
nmap <leader>P :set paste<CR>i
vmap <leader>p s<C-o>:set paste<CR>
" Exit paste mode when leaving insert mode
au InsertLeave * set nopaste

" Smart folding
au BufEnter * if !exists('b:all_folded') | let b:all_folded = 1 | endif
function! ToggleFold()
    if( b:all_folded == 0 )
        exec "normal! zM"
        let b:all_folded = 1
    else
        exec "normal! zR"
        let b:all_folded = 0
    endif
endfunction
nmap <Space> za
nmap <leader><Space> :call ToggleFold()<CR>

" Quickly toggle the quickfix window
" from http://vim.wikia.com/wiki/Toggle_to_open_or_close_the_quickfix_window
function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction
function! QuickfixToggle()
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "Quickfix List"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      cclose
      return
    endif
  endfor
  copen
endfunction
map <leader>q :call QuickfixToggle()<CR>

" Close the scratch preview automatically
autocmd CursorMovedI,InsertLeave * if pumvisible() == 0|pclose|endif

" Close quickfix if it's the only visible buffer
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" Attempt to expand a snippet. If no snippet exists, either autocomplete or
" insert a tab
let g:ulti_expand_or_jump_res = 0 "default value, just set once
let g:autocomplete_cmd = "\<C-P>"
function! CleverTab()
    call UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res == 0
      if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
          return "\<Tab>"
      else
          return g:autocomplete_cmd
      endif
    else
      return ''
    endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>
snoremap <Tab> <Esc>:call UltiSnips#ExpandSnippetOrJump()<cr>


" Do syntax checking on file open
let g:syntastic_check_on_open=1
" Don't use syntastic on python, use python-mode instead
let g:syntastic_mode_map = { 'mode': 'active',
                               \ 'passive_filetypes': ['python'] }

" Useful for removing whitespace after abbreviations
function! Eatchar(pat)
  let c = nr2char(getchar(0))
  return (c =~ a:pat) ? '' : c
endfunc

" BASH-style movement in insert mode
inoremap <C-a> <C-o>0
inoremap <C-e> <C-o>$

" Rebind ultisnips to something never used. We use CleverTab :)
let g:UltiSnipsExpandTrigger="<f12>"
let g:UltiSnipsJumpForwardTrigger="<f12>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"


" Put all my useful ultisnips globals in here
py import sys, os; sys.path.append(os.environ['HOME'] + '/.vim/UltiSnips/mods')

" Toggle nerdtree
nmap <leader>w :NERDTreeToggle<CR>

" EasyMotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings

let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <C-j> <Plug>(easymotion-j)
map <C-k> <Plug>(easymotion-k)

map f <Plug>(easymotion-s)


nmap <C-w><C-b> :tabedit %<CR>

" CTRLP
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_map = '<leader>t'
let g:ctrlp_by_filename = 1
if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " Map leader-g to grep the hovered word in the current workspace
  map <leader>g :grep <cword> <CR><CR> :copen <CR> <C-w><C-k>
else
  " Map leader-g to grep the hovered word in the current workspace
  map <leader>g :grep -IR <cword> * <CR><CR> :copen <CR> <C-w><C-k>
endif

nmap gs :Gstatus<CR>
nmap gh :Git! log -- %<CR>

" Configure vim-session
" Don't save help buffers
set sessionoptions-=help
" Don't save quickfix buffers
set sessionoptions-=qf
" Don't autoload sessions on startup
let g:session_autoload = 'no'
" Don't prompt to save on exit
let g:session_autosave = 'no'
let g:session_autosave_periodic = 1
let g:session_verbose_messages = 0
let g:session_command_aliases = 1
let g:session_menu = 0

" Helpful wrappers around vim-session
function! s:OverwriteQuickSave()
  let name = xolox#session#find_current_session()
  if !empty(name)
    " If we have a current session name, disable the save callback and remap
    " <leader>ss to save with no prompt.
    aug SessionSaveTrigger
      au!
    aug END
    nnoremap <leader>ss :wa<CR>:SaveSession<CR>
  endif
endfunction
augroup SessionSaveTrigger
  au!
  au BufWrite,BufRead * :call s:OverwriteQuickSave()
augroup END
nmap <leader>ss :wa<CR>:SaveSession 

let g:ctrlp_extensions = ['session_wrapper']
nnoremap <leader>so :call session_wrapper#QuickOpen()<CR>
nnoremap <leader>sd :call session_wrapper#SafeDelete()<CR>
nnoremap <leader>zz :wa<CR>:SaveSession! quicksave<CR>:qa<CR>
function! s:QuickLoad()
  if !xolox#session#is_empty()
    return
  endif
  let names = xolox#session#get_names(0)
  for name in names
    if name == 'quicksave'
      SessionOpen quicksave
      SessionDelete! quicksave
      let v:this_session = ''
    endif
  endfor
endfunction
aug QuickLoad
  au!
  au VimEnter * nested call s:QuickLoad()
aug END

" Use cjsx to build because it's a superset of coffeescript
let coffee_compiler = '/usr/local/nvm/versions/io.js/v2.3.1/bin/cjsx'
" Make syntastic work with cjsx files
let g:syntastic_coffee_coffee_exe = '/usr/local/nvm/versions/io.js/v2.3.1/bin/cjsx'
