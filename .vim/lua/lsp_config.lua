local util = require 'nvim_lsp/util'
local aerial = require 'aerial'

aerial.set_open_automatic{
  ['_'] = false,
}

local mapper = function(mode, key, result)
  vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap = true, silent = true})
end

local ts_lsp_config = {
  autoformat = true
}
local js_lsp_config = { }
local ft_config = {
  vim = {
    help = false
  },
  cs = {
    autoformat = true,
    code_action = false, -- TODO: this borks the omnisharp server
  },
  rust = {
    autoformat = true
  },
  typescript = ts_lsp_config,
  typescriptreact = ts_lsp_config,
  ['typescript.jsx'] = ts_lsp_config,
  javascript = js_lsp_config,
  javascriptreact = js_lsp_config,
  ['javascript.jsx'] = js_lsp_config,
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
  }
)

local M = {}

M.on_attach = function(client)
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local config = ft_config[ft] or {}

  -- Make all the "jump" commands call zvzz after execution
  local jump_callbacks = {
    'textDocument/declaration',
    'textDocument/definition',
    'textDocument/typeDefinition',
    'textDocument/implementation',
  }
  for _,cb in pairs(jump_callbacks) do
    local orig_callback = vim.lsp.callbacks[cb]
    local new_callback = function(idk, method, result)
      orig_callback(idk, method, result)
      vim.cmd('normal! zvzz')
    end
    vim.lsp.callbacks[cb] = new_callback
  end

  -- Aerial
  vim.api.nvim_set_var('aerial_open_automatic_min_lines', 200)
  vim.api.nvim_set_var('aerial_open_automatic_min_symbols', 10)
  mapper('n', '<leader>a', '<cmd>lua require"aerial".toggle()<CR>')
  mapper('n', '{', '<cmd>lua require"aerial".prev_item()<CR>zvzz')
  mapper('v', '{', '<cmd>lua require"aerial".prev_item()<CR>zvzz')
  mapper('n', '}', '<cmd>lua require"aerial".next_item()<CR>zvzz')
  mapper('v', '}', '<cmd>lua require"aerial".next_item()<CR>zvzz')

  -- Standard LSP
  mapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  mapper('n', 'tgd', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  mapper('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  mapper('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  mapper('n', 'gs', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  if config.help ~= false then
    mapper('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  end
  mapper('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  mapper('i', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  if config.code_action ~= false then
    mapper('n', '<leader><space>', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  end
  mapper('n', '=', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('v', '=', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')
  mapper('n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>')

  mapper('n', '<space>', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  if config.cursor_highlight == true then
    vim.cmd [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]
  end

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")

  -- TODO should check my custom autoformat dict
  if config.autoformat then
    vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]]
  end

  aerial.on_attach(client)
end

require'nvim_lsp'.bashls.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.gdscript.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.clangd.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.html.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.jsonls.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.omnisharp.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.pyls_ms.setup{
  on_attach = M.on_attach,
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
  on_attach = M.on_attach,
}
require'nvim_lsp'.tsserver.setup{
  on_attach = M.on_attach,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
  root_dir = util.root_pattern("tsconfig.json", ".git");
}
require'nvim_lsp'.vimls.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.yamlls.setup{
  on_attach = M.on_attach,
}
require'nvim_lsp'.flow.setup{
  on_attach = M.on_attach,
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

return M
