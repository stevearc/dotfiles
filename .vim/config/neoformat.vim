let g:neoformat_enabled_json = ['prettier']
let g:neoformat_enabled_less = ['prettier']

let fmt = 'clang-format'
if !executable(fmt) && executable('clang-format-6.0')
  let fmt = 'clang-format-6.0'
endif

let g:neoformat_cpp_clangformat = {
  \ 'exe': fmt,
  \ 'stdin': 1,
  \ }


let g:smartformat_enabled = 1

command! -bar FormatDisable let g:smartformat_enabled = 0
command! -bar FormatEnable let g:smartformat_enabled = 1
