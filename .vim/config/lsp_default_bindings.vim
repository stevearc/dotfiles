if luaeval('vim.lsp == null')
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
      return '%f ' . lsp_addons#StatusLine()
  endfunction

  augroup LSPStatusLine
    autocmd! * <buffer>
    autocmd BufWinEnter <buffer> setlocal statusline=%!LSPStatusLine()
  augroup END
else
  nnoremap <silent> gd        <cmd>lua vim.lsp.buf.definition()<CR>
  nnoremap <silent> 1gD       <cmd>lua vim.lsp.buf.type_definition()<CR>
  nnoremap <silent> 2gd       <cmd>lua vim.lsp.buf.declaration()<CR>
  nnoremap <silent> K         <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> gi        <cmd>lua vim.lsp.buf.implementation()<CR>
  nnoremap <silent> <c-k>     <cmd>lua vim.lsp.buf.signature_help()<CR>
  nnoremap <silent> gr        <cmd>lua vim.lsp.buf.references()<CR>
  nnoremap <silent> g0        <cmd>lua vim.lsp.buf.document_symbol()<CR>
  nnoremap <silent> gW        <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
  nnoremap <buffer> <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
  nnoremap <buffer> <leader>r <cmd>lua vim.lsp.buf.rename()<CR>
  vnoremap <buffer> <leader>f <cmd>lua vim.lsp.buf.range_formatting()<CR>

  " TODO
  " code actions

  setlocal omnifunc=v:lua.vim.lsp.omnifunc
endif
