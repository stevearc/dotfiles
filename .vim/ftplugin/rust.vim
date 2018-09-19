let b:ale_linters = ['rls']

nnoremap <buffer> gd <Plug>(rust-def)
nnoremap <buffer> K <Plug>(rust-doc)

se makeprg=cargo\ build

augroup rustfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('rust', 'Neoformat')
augroup END
