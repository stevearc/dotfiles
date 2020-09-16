" detail view
let g:netrw_liststyle = 1
" vsplit the preview
let g:netrw_preview = 1
" Show human-readable sizes
let g:netrw_sizestyle = "H"
" Preview splits right
let g:netrw_alto = 0
" Don't let Lexplore change the behavior of <cr>
let g:netrw_chgwin = 0
" Default win size (not working?)
" let g:netrw_winsize = 10

function! s:ToggleTree() abort
    let oldval = g:netrw_liststyle
    let g:netrw_liststyle = 3
    Lexplore
    let g:netrw_liststyle = oldval
endfunction

command! ToggleTree call s:ToggleTree()
" nnoremap <leader>w :ToggleTree<cr>
