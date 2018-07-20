if has('gui_running') || $COLORTERM ==# "truecolor"
  set termguicolors
endif

" SOLARIZED
let g:solarized_visibility="high"
function! s:SetSolarized() abort
  colorscheme solarized8_high
endfunction

" space-vim
let g:space_vim_dark_background = 234
function! s:SetSpaceVim() abort
  set background=dark
  colorscheme space-vim-dark
  hi LineNr guifg=#5C6370 ctermfg=59
endfunction

set background=dark
call s:SetSolarized()

command! ColorSpaceVim call s:SetSpaceVim()
command! ColorSolarized call s:SetSolarized()

