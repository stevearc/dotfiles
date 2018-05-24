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
