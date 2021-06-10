let g:solarized_extra_hi_groups = 1

" Let's optimistically do this. Refer to https://github.com/termstandard/colors
" if we encounter an environment where it breaks.
set termguicolors

lua <<END
require 'colorizer'.setup()

if vim.g.devicons ~= false then
  require'nvim-web-devicons'.setup {
   default = true;
  }
end
END

set background=dark
colorscheme solarized8
