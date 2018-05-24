nnoremap <buffer> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <buffer> gd :call LanguageClient#textDocument_definition()<CR>zz
nnoremap <buffer> gr :call LanguageClient#textDocument_references()<CR>:lw<CR>
