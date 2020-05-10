if has('gui_running') || $COLORTERM ==# "truecolor"
  set termguicolors
endif

let g:solarized_extra_hi_groups = 1

" SOLARIZED
function! s:SetSolarized() abort
  colorscheme solarized8
endfunction

" space-vim
function! s:SetSpaceVim() abort
  colorscheme space_vim_theme
endfunction

set background=dark
call s:SetSolarized()

command! ColorSpaceVim call s:SetSpaceVim()
command! ColorSolarized call s:SetSolarized()

