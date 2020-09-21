let g:solarized_extra_hi_groups = 1

" Let's optimistically do this. Refer to https://github.com/termstandard/colors
" if we encounter an environment where it breaks.
set termguicolors

lua <<END
require 'colorizer'.setup()
END

set background=dark
colorscheme solarized8
