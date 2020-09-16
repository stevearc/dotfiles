if luaeval('vim.lsp == null')
  finish
endif

function! LSPStatusLine() abort
    return '%m%f ' . lsp_addons#StatusLine() . ' %=%l,%c'
endfunction
let &l:statusline = '%!LSPStatusLine()'

nnoremap <silent> <buffer> gd        <cmd>lua vim.lsp.buf.definition()<CR>zz
nnoremap <silent> <buffer> gt        <cmd>lua vim.lsp.buf.type_definition()<CR>zz
nnoremap <silent> <buffer> gD        <cmd>lua vim.lsp.buf.declaration()<CR>zz
nnoremap <silent> <buffer> K         <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> <buffer> gi        <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <buffer> <c-k>     <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> <buffer> gr        <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> <buffer> g0        <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> <buffer> gs        <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nnoremap <silent> <buffer> <leader><space> <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> <buffer> <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <silent> <buffer> <leader>r <cmd>lua vim.lsp.buf.rename()<CR>
vnoremap <silent> <buffer> <leader>f <cmd>lua vim.lsp.buf.range_formatting()<CR>

augroup HighlightHold
  autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
  autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
  autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
augroup end

setlocal omnifunc=v:lua.vim.lsp.omnifunc
