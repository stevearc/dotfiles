se makeprg=cargo\ $*

function! CargoRun() abort
  :w
  :silent !clear
  :botright split | terminal cargo run
endfunction

nnoremap <leader>e :call CargoRun()<CR>
