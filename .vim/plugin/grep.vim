if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  set grepprg=ag\ --vimgrep\ $*
  set grepformat=%f:%l:%c:%m
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
elseif !empty(fugitive#extract_git_dir(expand('%:p')))
  set grepprg=git\ --no-pager\ grep\ --no-color\ -n\ $*
  set grepformat=%f:%l:%m,%m\ %f\ match%ts,%f
else
  set grepprg=grep\ -nIR\ $*\ .
endif

function! BufGrep(text) abort
  cclose
  %argd
  let buf = bufnr('%')
  bufdo argadd %
  exec 'b' buf
  exec 'vimgrep /' . a:text . '/ ##'
  lua require'qf_helper'.open('c')
endfunction

nnoremap <leader>g <cmd>cclose \| silent grep! <cword> \| lua require'qf_helper'.open('c')<CR>
command! -nargs=+ Bufgrep call BufGrep('<args>')
nnoremap gR :call BufGrep(expand('<cword>'))<CR>
