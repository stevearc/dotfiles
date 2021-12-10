se makeprg=cargo\ $*

function! s:CargoRun() abort
  write
  silent !clear
  botright split
  terminal cargo run
endfunction

nnoremap <leader>e <cmd>call <sid>CargoRun()<CR>
