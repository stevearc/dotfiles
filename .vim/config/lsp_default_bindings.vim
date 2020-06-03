function! LSPStatusLine() abort
    return '%f ' . lsp_addons#StatusLine() . ' %=%l,%c'
endfunction
let &l:statusline = '%!LSPStatusLine()'

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

else
  nnoremap <silent> <buffer> gd        <cmd>lua vim.lsp.buf.definition()<CR>zz
  nnoremap <silent> <buffer> gD        m':$tab split<CR><cmd>lua vim.lsp.buf.definition()<CR>zz
  nnoremap <silent> <buffer> 1gd       <cmd>lua vim.lsp.buf.type_definition()<CR>zz
  nnoremap <silent> <buffer> 2gd       <cmd>lua vim.lsp.buf.declaration()<CR>zz
  nnoremap <silent> <buffer> K         <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> <buffer> gi        <cmd>lua vim.lsp.buf.implementation()<CR>
  nnoremap <silent> <buffer> <c-k>     <cmd>lua vim.lsp.buf.signature_help()<CR>
  nnoremap <silent> <buffer> gr        <cmd>lua vim.lsp.buf.references()<CR>
  nnoremap <silent> <buffer> g0        <cmd>lua vim.lsp.buf.document_symbol()<CR>
  nnoremap <silent> <buffer> gW        <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
  nnoremap <silent> <buffer> <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
  nnoremap <silent> <buffer> <leader>r <cmd>lua vim.lsp.buf.rename()<CR>
  vnoremap <silent> <buffer> <leader>f <cmd>lua vim.lsp.buf.range_formatting()<CR>

  " TODO
  " code actions

  " This produces errors right now. Possibly will be fixed in a later neovim
  " setlocal omnifunc=v:lua.vim.lsp.omnifunc
endif
