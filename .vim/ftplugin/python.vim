" python-mode options
let b:neoformat_enabled_python = ['black']

" Use deoplete-jedi for completion
let g:jedi#completions_enabled = 0
let g:jedi#auto_initialization = 0
setlocal omnifunc=jedi#completions
call jedi#configure_call_signatures()

nnoremap gd :call jedi#goto()<CR>
nnoremap ga :call jedi#goto_assignments()<CR>
nnoremap gr :call jedi#usages()<CR>
nnoremap <leader>r :call jedi#rename()<CR>
vnoremap <leader>r :call jedi#rename_visual()<CR>

command! -buffer -bar JediShowDocumentation call jedi#show_documentation()
setlocal keywordprg=":JediShowDocumentation"

let g:deoplete#sources#jedi#show_docstring = 1

" Abbreviations
iabbr <buffer> inn is not None
iabbr <buffer> ipmort import
iabbr <buffer> improt import

" Foxdot
nnoremap <buffer> <CR> :call system('nc localhost 7088', getline('.'))<CR>
vnoremap <buffer> <CR> y:call system('nc localhost 7088', @")<CR>

augroup PythonOptions
  au! * <buffer>
  autocmd BufWinEnter <buffer> setlocal shiftwidth=4 tabstop=4 softtabstop=4 tw=88
augroup END

augroup pyfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('python', 'Neoformat')
augroup END
