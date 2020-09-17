local util = require 'nvim_lsp/util'

local mapper = function(mode, key, result)
  vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap = true, silent = true})
end

local custom_attach = function(client)
  mapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>zz')
  mapper('n', '1gd', '<cmd>lua vim.lsp.buf.declaration()<CR>zz')
  mapper('n', '2gd', '<cmd>lua vim.lsp.buf.type_definition()<CR>zz')
  mapper('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  mapper('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  mapper('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  mapper('i', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  mapper('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  -- These are not useful yet :/
  -- mapper('n', 'g0', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  -- mapper('n', 'gs', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  mapper('n', '<leader><space>', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  mapper('n', '<leader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>')
  mapper('v', '<leader>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')

  mapper('n', '<space>', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')
  vim.cmd [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
  vim.cmd [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
  vim.cmd [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")

  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local autoformat_fts = {
    ['rust'] = true,
    ['typescript'] = true,
    ['typescriptreact'] = true,
    ['typescript.jsx'] = true
  }
  if autoformat_fts[ft] then
    vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]]
  end

end

require'nvim_lsp'.bashls.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.gdscript.setup{
  on_attach = custom_attach,
}
-- require'nvim_lsp'.omnisharp.setup{}
require'nvim_lsp'.clangd.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.html.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.jsonls.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.pyls_ms.setup{
  on_attach = custom_attach,
  settings = {
    python = {
      analysis = {
        disabled = {},
        errors = {
          'inherit-non-classpath',
          'no-cls-argument',
          'no-method-argument',
          'no-self-argument',
          'parameter-already-specified',
          'parameter-missing',
          'positional-argument-after-keyword',
          'positional-only-named',
          'return-in-init',
          'too-many-function-arguments',
          'typing-typevar-arguments',
          'undefined-variable',
          'unknown-parameter-name',
          'unknown-parameter-name',
          'unresolved-import',
          'variable-not-defined-globally',
          'variable-not-defined-nonlocal',
        },
        info = {}
      }
    }
  }
}
require'nvim_lsp'.rust_analyzer.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.tsserver.setup{
  on_attach = custom_attach,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
  root_dir = util.root_pattern("tsconfig.json", ".git");
}
require'nvim_lsp'.vimls.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.yamlls.setup{
  on_attach = custom_attach,
}
require'nvim_lsp'.flow.setup{
  on_attach = custom_attach,
  cmd = {"flow", "lsp", "--lazy"};
  settings = {
    flow = {
      coverageSeverity = "warn";
      showUncovered = true;
      stopFlowOnExit = false;
      useBundledFlow = false;
    }
  }
}
