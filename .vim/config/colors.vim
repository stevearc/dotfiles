let g:solarized_extra_hi_groups = 1

" Let's optimistically do this. Refer to https://github.com/termstandard/colors
" if we encounter an environment where it breaks.
set termguicolors

lua <<END
require 'colorizer'.setup()
END

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

