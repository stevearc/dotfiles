if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  set grepprg=ag\ --vimgrep\ $*
  set grepformat=%f:%l:%c:%m
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
elseif luaeval('require("lspconfig.util").find_git_ancestor(vim.loop.cwd())') != v:null
  set grepprg=git\ --no-pager\ grep\ --no-color\ -n\ $*
  set grepformat=%f:%l:%m,%m\ %f\ match%ts,%f
else
  set grepprg=grep\ -nIR\ $*\ .
endif

function! s:Bufgrep(text) abort
  cclose
  %argd
  let l:buf = nvim_get_current_buf()
  bufdo argadd %
  call nvim_set_current_buf(l:buf)
  exec 'silent! vimgrep /' . a:text . '/gj ##'
  QFOpen!
endfunction

nnoremap gw <cmd>cclose \| silent grep! <cword> \| QFOpen!<CR>
command! -nargs=+ Bufgrep call <sid>Bufgrep('<args>')
nnoremap gbw <cmd>call <sid>Bufgrep(expand('<cword>'))<CR>
