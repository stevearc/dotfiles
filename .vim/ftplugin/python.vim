" python-mode options
let b:neoformat_enabled_python = ['isort', 'black']
let b:neoformat_run_all_formatters = 1

" Try using pyls instead of jedi-vim
source ~/.vim/config/lsp_default_bindings.vim

" Use deoplete-jedi for completion
let g:jedi#completions_enabled = 0
let g:jedi#auto_initialization = 0

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
