function! EnableBinary() abort
  let s:curpos = getcurpos()
  augroup Binary
    au! * <buffer>
    au BufWritePre <buffer> let s:curpos = getcurpos()
    au BufWritePre <buffer> undojoin | silent %!xxd -r
    au BufWritePost <buffer> undojoin | silent %!xxd
    au BufWritePost <buffer> set nomod
    au BufWritePost <buffer> call setpos('.', s:curpos)
  augroup END
  set bin
  let l:mod = &mod
  silent %!xxd
  let &mod = l:mod
  set ft=xxd
endfunction

function! DisableBinary() abort
  augroup Binary
    au! * <buffer>
  augroup END
  let l:mod = &mod
  silent %!xxd -r
  let &mod = l:mod
  set ft=
endfunction

command! Hex :call EnableBinary()
command! HexOff :call DisableBinary()
