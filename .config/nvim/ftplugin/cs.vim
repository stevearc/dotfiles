" Use % to jump between region/endregion
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

se foldlevelstart=0
let b:all_folded = 1

augroup csopts
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal tw=100 foldmethod=syntax
augroup END
