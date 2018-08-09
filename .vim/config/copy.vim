function! s:OnExit(job_id, exit_code, event) abort
  if a:exit_code == 0
    let g:use_clipper = 1
  endif
  call s:BindCopy()
endfunction

function! s:BindCopy() abort
  if get(g:, 'use_clipper')
    nnoremap <leader>y :call system('nc localhost 8377', @0)<CR>
  elseif executable('xsel')
    nnoremap <leader>y :call system('xsel -ib', @0)<CR>
  elseif executable('pbcopy')
    nnoremap <leader>y :call system('pbcopy', @0)<CR>
  elseif executable('xclip')
    nnoremap <leader>y :call system('xclip -i -sel clip > /dev/null', @0)<CR>
  endif
endfunction

if !exists('g:use_clipper') && executable('nc') && exists('*jobstart')
  call jobstart(['nc', '-z', 'localhost', '8377'], { 'on_exit': function('s:OnExit') })
else
  call s:BindCopy()
endif
