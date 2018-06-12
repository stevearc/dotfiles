if !exists('g:use_clipper') && executable('nc')
  call system('nc -z localhost 8377')
  if v:shell_error == 0
    let g:use_clipper = 1
  endif
endif

if exists('g:use_clipper') && g:use_clipper
  nnoremap <leader>y :call system('nc localhost 8377', @0)<CR>
elseif executable('xsel')
  nnoremap <leader>y :call system('xsel -ib', @0)<CR>
elseif executable('pbcopy')
  nnoremap <leader>y :call system('pbcopy', @0)<CR>
elseif executable('xclip')
  nnoremap <leader>y :call system('xclip -i -sel clip > /dev/null', @0)<CR>
endif
