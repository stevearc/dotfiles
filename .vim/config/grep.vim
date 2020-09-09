" Set grep program and map leader-g to grep the hovered word in the current workspace

if executable('ag')
  set grepprg=ag\ --vimgrep\ $*
  set grepformat=%f:%l:%c:%m
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
else
endif

function! BufGrep(text) abort
  %argd
  let buf = bufnr('%')
  bufdo argadd %
  exec 'b' buf
  exec 'vimgrep /' . a:text . '/ ##'
  call quickerfix#Open('c')
endfunction

nnoremap <leader>g :call smartgrep#grep(expand('<cword>'))<CR>
command! -nargs=+ Bufgrep call BufGrep('<args>')
nnoremap gR :call BufGrep(expand('<cword>'))<CR>
