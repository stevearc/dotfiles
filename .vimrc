let g:ale_emit_conflict_warnings = 0
" Load plugins from the bundle directory
call pathogen#infect()
call pathogen#helptags()

" Use this file to set neovim python paths so it works with virtualenvs
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

" Use 4-space tabs for certain file types
au FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4
" Trim trailing whitespace on save
function! TrimTrailingWhitespace()
  :%s/\s\+$//ge
endfunction
command! TrimTrailingWhitespace :call TrimTrailingWhitespace()
" Note js & json excluded because we use Neoformat
autocmd BufWrite *.coffee,*.cjsx,*.jsx,*.html,*.jinja2,*.j2,*.css,*.less,*.styl,*.py,*.rb,*.go,*.ino,*.c,*.cpp,*.h,*.sh if ! &bin | silent! call TrimTrailingWhitespace() | endif

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

" Deoplete
let g:deoplete#enable_at_startup = 1
" Disable the candidates in Comment/String syntaxes.
call deoplete#custom#source('_', 'disabled_syntaxes', ['Comment', 'String'])
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
call deoplete#custom#var('omni', 'input_patterns', {
    \ 'ruby': ['[^. *\t]\.\w*', '[a-zA-Z_]\w*::'],
    \ 'java': '[^. *\t]\.\w*',
    \ 'cs': '\w+|[^. *\t]\.\w*',
    \ 'php': '\w+|[^. \t]->\w*|\w+::\w*',
    \})
call deoplete#custom#option('min_pattern_length', 1)
call deoplete#custom#option('sources', {
\ '_': ['ultisnips'],
\ 'cs': ['omni', 'ultisnips'],
\ 'sh': ['LanguageClient', 'ultisnips'],
\ 'javascript': ['LanguageClient', 'ultisnips'],
\})

let g:LanguageClient_serverCommands = {
\ 'sh': ['bash-language-server', 'start'],
\ 'javascript': ['flow-language-server', '--stdio']
\ }

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

" Utility for finding system executables
function! FindExecutable(name)
  let path = substitute(system('command -v ' . a:name), "\n*$", '', '')
  if empty(path) | return 0 | endif
  let abspath = resolve(path)
  return abspath
endfunction

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
    elseif match(expand("%"), '.js$') != -1
        exec ":!node " . @%
    elseif match(expand("%"), '.clj$') != -1
        exec ":%Eval"
        exec ":redraw!"
    else
        :redraw!
        :echo "Unknown file type"
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
nmap <C-w>z :resize<CR>:vertical resize<CR>
set splitbelow
set splitright

" Expand %% to current directory in command mode
cabbr <expr> %% expand('%:p:h')

" Go to next/prev result with <Ctrl> + n/p
function! NextResult()
  if IsBufferOpen("Location List")
    lnext
  else
    cnext
  endif
  exec "normal! zv"
endfunction
function! PrevResult()
  if IsBufferOpen("Location List")
    lprev
  else
    cprev
  endif
  exec "normal! zv"
endfunction
nnoremap <silent> <C-N> :call NextResult()<CR>
nnoremap <silent> <C-P> :call PrevResult()<CR>

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

" Customizations for terminal mode
tnoremap <leader><leader> <C-\><C-N>
tnoremap <leader>1 <C-\><C-N>1gt
tnoremap <leader>2 <C-\><C-N>2gt
tnoremap <leader>3 <C-\><C-N>3gt
tnoremap <leader>4 <C-\><C-N>4gt
tnoremap <leader>5 <C-\><C-N>5gt
tnoremap <leader>6 <C-\><C-N>6gt
tnoremap <leader>7 <C-\><C-N>7gt
tnoremap <leader>8 <C-\><C-N>8gt
tnoremap <leader>9 <C-\><C-N>9gt
tnoremap <leader>h <C-\><C-N>:wincmd h<CR>
tnoremap <leader>l <C-\><C-N>:wincmd l<CR>
tnoremap <leader>j <C-\><C-N>:wincmd j<CR>
tnoremap <leader>k <C-\><C-N>:wincmd k<CR>
tnoremap <leader>: <C-\><C-N>:
highlight TermCursor ctermfg=DarkRed guifg=red
au BufEnter * if &buftype == 'terminal' | :startinsert | endif

au FocusGained * checktime

" Navigate tabs with H and L
" We can't rebind <Tab> because that's equivalent to <C-i> and we want to keep
" the <C-i>/<C-o> navigation :/
nmap L gt
nmap H gT

" Enter paste mode with <C-v> in insert mode
imap <C-v> <C-o>:set paste<CR>
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
nmap <leader><Space> :call ToggleFold()<CR>

" Quickly toggle the quickfix window
" from http://vim.wikia.com/wiki/Toggle_to_open_or_close_the_quickfix_window
function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction
function! IsBufferOpen(name)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ a:name'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      return 1
    endif
  endfor
  return 0
endfunction
function! QuickfixToggle()
  if IsBufferOpen("Quickfix List")
    cclose
  else
    copen
  endif
endfunction
map <leader>q :call QuickfixToggle()<CR>
function! LocationListToggle()
  if IsBufferOpen("Location List")
    lclose
  else
    lopen
  endif
endfunction
map <leader>l :call LocationListToggle()<CR>

" Close the scratch preview automatically
augroup CloseScratch
  au!
  autocmd CursorMovedI,InsertLeave * if pumvisible() == 0|pclose|endif
augroup END

" Close quickfix if it's the only visible buffer
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" Attempt to expand a snippet. If no snippet exists, either autocomplete or
" insert a tab
let g:ulti_expand_or_jump_res = 0 "default value, just set once
let g:autocomplete_cmd = "\<C-x>\<C-o>"
function! CleverTab()
    call UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res == 0
      if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
          return "\<Tab>"
      elseif &omnifunc == ''
          return "\<C-n>"
      else
          return g:autocomplete_cmd
      endif
    else
      return ''
    endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>
snoremap <Tab> <Esc>:call UltiSnips#ExpandSnippetOrJump()<cr>

" Rebind ultisnips to something never used. We use CleverTab :)
let g:UltiSnipsExpandTrigger="<f12>"
let g:UltiSnipsJumpForwardTrigger="<f12>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" Put all my useful ultisnips globals in here
py import sys, os; sys.path.append(os.environ['HOME'] + '/.vim/UltiSnips/mods')

" Useful for removing whitespace after abbreviations
function! Eatchar(pat)
  let c = nr2char(getchar(0))
  return (c =~ a:pat) ? '' : c
endfunc

" BASH-style movement in insert mode
inoremap <C-a> <C-o>0
inoremap <C-e> <C-o>$

" EasyMotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings

let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <C-j> <Plug>(easymotion-j)
map <C-k> <Plug>(easymotion-k)

map <leader>f <Plug>(easymotion-s)


nmap <C-w><C-b> :tabedit %<CR>

" CTRLP
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_switch_buffer = 'eTvh'
let g:ctrlp_lazy_update = 1
let g:ctrlp_map = '<leader>t'
let g:ctrlp_by_filename = 1
nnoremap <leader>b :CtrlPBuffer<CR>

if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " Map leader-g to grep the hovered word in the current workspace
  map <leader>g :grep <cword> <CR><CR> :copen <CR> <C-w><C-k>
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ack --nocolor -f %s'
  " Map leader-g to grep the hovered word in the current workspace
  map <leader>g :grep <cword> <CR><CR> :copen <CR> <C-w><C-k>
else
  " Map leader-g to grep the hovered word in the current workspace
  map <leader>g :grep -IR <cword> * <CR><CR> :copen <CR> <C-w><C-k>
endif

nmap <leader>gs :Gstatus<CR>
nmap <leader>gh :Git! log -- %<CR>

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
let g:session_name_suggestion_function = "session_wrapper#vcs_feature_branch"

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
  let names = xolox#session#get_names(0)
  for name in names
    if name == 'quicksave'
      SessionOpen quicksave
      SessionDelete! quicksave
    endif
  endfor
endfunction
aug QuickLoad
  au!
  au VimEnter * nested call s:QuickLoad()
aug END

" Use cjsx to build because it's a superset of coffeescript
let coffee_compiler = FindExecutable('cjsx')

aug Colorize
  au!
  au BufReadPost * command! -buffer -bar Colorize call css_color#init('css', 'extended', 'cssFunction')
aug END

" Shortcut for clipper
nnoremap <leader>y :call system('nc localhost 8377', @0)<CR>

" Omnisharp
let g:Omnisharp_start_server = 0

" Syntastic (which we really only need for omnisharp)
let g:syntastic_cs_checkers = ['code_checker']
let g:syntastic_check_on_wq = 0
let g:syntastic_mode_map = {
    \ "mode": "passive",
    \ "active_filetypes": ["cs"] }


" Cmdr
function! Cmdr(cmd)
  call system('nc localhost 8585', a:cmd)
endfunction

" Neoformat
let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_enabled_json = ['prettier']
let g:neoformat_enabled_css = ['prettier']
let g:neoformat_enabled_less = ['prettier']
let g:neoformat_enabled_cpp = ['clangformat']
let g:neoformat_cpp_clangformat = {
  \ 'exe': 'clang-format-6.0',
  \ 'stdin': 1,
  \ }

" Ale
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_cpp_clangtidy_executable = 'clang-tidy-6.0'
let g:ale_linters = {
\   'javascript': ['flow'],
\   'cpp': ['clangtidy'],
\}

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1

function! ProseMode()
  setlocal spell noci nosi noai nolist noshowmode noshowcmd nonu
  setlocal complete+=s
  setlocal formatoptions+=t
endfunction

command! ProseMode call ProseMode()
