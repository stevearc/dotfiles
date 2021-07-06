se makeprg=cargo\ $*

function! CargoRun() abort
  write
  silent !clear
  botright split
  terminal cargo run
endfunction

nnoremap <leader>e :call CargoRun()<CR>
