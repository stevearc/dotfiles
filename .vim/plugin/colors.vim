let g:solarized_extra_hi_groups = 1
let g:solarized_statusline = 'flat'

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

" solarized8 is missing some colors for LSP
highlight link LspDiagnosticsDefaultError ALEError
highlight link LspDiagnosticsSignError ALEErrorSign
highlight link LspDiagnosticsDefaultWarning ALEWarning
highlight link LspDiagnosticsSignWarning ALEWarningSign
highlight link LspDiagnosticsDefaultInformation ALEInfo
highlight link LspDiagnosticsSignInformation ALEInfoSign
highlight link LspDiagnosticsDefaultHint ALEInfo
highlight link LspDiagnosticsSignHint ALEInfoSign

hi JustUnderline gui=undercurl cterm=undercurl
highlight link LspDiagnosticsUnderlineError JustUnderline
highlight link LspDiagnosticsUnderlineWarning JustUnderline
highlight link LspDiagnosticsUnderlineInformation JustUnderline
highlight link LspDiagnosticsUnderlineHint JustUnderline

" I don't like the underlined virtual text
hi ALEError gui=NONE cterm=NONE
hi ALEInfo gui=NONE cterm=NONE
hi ALEWarning gui=NONE cterm=NONE
