nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> <leader>f :call LanguageClient_textDocument_formatting()<CR>

iabbr <buffer> inn is nonnull

augroup hackfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if @format is in the top
  autocmd BufWritePre <buffer> call hackfmt#SmartFormat()
augroup END
