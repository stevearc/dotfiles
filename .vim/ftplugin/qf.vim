" Quickfix windows don't have to have a lot of height
exec "setlocal winheight=" . g:qf_min_height

nnoremap <buffer> <C-t> <C-W><CR><C-W>T

" Remove the zz behavior when going up/down in quickfix
nnoremap <buffer> <C-d> <C-d>
nnoremap <buffer> <C-u> <C-u>
nnoremap <buffer> G G
nnoremap <buffer> j gj
nnoremap <buffer> k gk
vnoremap <buffer> j gj
vnoremap <buffer> k gk
