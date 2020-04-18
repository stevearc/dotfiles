nnoremap <buffer> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <buffer> gd :call LanguageClient_textDocument_definition()<CR>
nnoremap <buffer> gi :call LanguageClient_textDocument_implementation()<CR>
nnoremap <buffer> <leader>r :call LanguageClient_textDocument_rename()<CR>
nnoremap <buffer> gD m':$tab split<CR>:call LanguageClient#textDocument_definition()<CR>zz
nnoremap <buffer> <leader>f :call LanguageClient_textDocument_formatting()<CR>
nnoremap <buffer> gr :call LanguageClient#textDocument_references()<CR>:lw<CR>
nnoremap <buffer> <leader><space> :call LanguageClient#textDocument_codeAction()<CR>
vnoremap <buffer> <leader>f :call LanguageClient#textDocument_rangeFormatting()<CR>

function! LSPStatusLine() abort
    return '%f ' . lsp#StatusLine()
endfunction

augroup LSPStatusLine
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal statusline=%!LSPStatusLine()
augroup END
