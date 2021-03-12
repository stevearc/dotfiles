local aerial = require 'aerial'
local completion = require("completion")

aerial.set_open_automatic{
  ['_'] = false,
}

require('telescope').setup{
  defaults = {
    winblend = 10,
  }
}

local mapper = function(mode, key, result)
  vim.api.nvim_buf_set_keymap(0, mode, key, result, {noremap = true, silent = true})
end

local is_loclist_visible = function()
  local win_info = vim.fn.getwininfo()
  for _,info in ipairs(win_info) do
    if info.loclist == 1 then
      return true
    end
  end
  return false
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

-- Completion
if vim.g.completion_plugin == 'completion' then
  vim.cmd[[autocmd BufEnter * lua require'completion'.on_attach()]]
end
if vim.g.use_ultisnips ~= 0 then
  vim.g.completion_enable_snippet = 'UltiSnips'
else
  vim.g.completion_enable_snippet = 'vim-vsnip'
end
vim.g.completion_confirm_key = ""
vim.g.completion_matching_smart_case = 1
vim.g.completion_matching_strategy_list = {'exact', 'fuzzy'}

completion.addCompletionSource("glsl", {item = require'completion.source.glsl_keywords'.get_completion_items})

vim.g.completion_chain_complete_list = {
  glsl = {
    {complete_items = {'glsl', 'buffers'}},
    {complete_items = {'snippet'}},
  },
  default = {
    {complete_items = {'lsp'}},
    {complete_items = {'buffers'}},
    {complete_items = {'snippet'}},
  },
}
vim.g.completion_auto_change_source = 1

if vim.g.completion_plugin == 'compe' then
  require'compe'.setup {
    enabled = true;
    debug = false;
    min_length = 1;
    source = {
      path = false;
      buffer = false;
      vsnip = true;
      nvim_lsp = true;
    };
  }
end


local M = {}

M.on_update_diagnostics = function(bufnr)
  local mode = vim.api.nvim_get_mode()
  if string.sub(mode.mode, 1, 1) == 'i' then return end

  local errors = vim.lsp.diagnostic.get_count(bufnr, "Error")
  local warnings = vim.lsp.diagnostic.get_count(bufnr, "Warning")
  if warnings + errors == 0 then
    vim.lsp.util.set_loclist({})
    vim.cmd('lclose')
  else
    vim.lsp.diagnostic.set_loclist({open_loclist = false})
    -- Resize the loclist
    if is_loclist_visible() then
      local winid = vim.fn.win_getid()
      local height = math.max(vim.g.qf_min_height, math.min(vim.g.qf_max_height, errors + warnings))
      vim.cmd('lopen '..height)
      vim.fn.win_gotoid(winid)
    end
  end
end

M.on_init = function(client)
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local config = ft_config[ft] or {}

  client.config.flags = {}
  if client.config.flags then
    client.config.flags.allow_incremental_sync = config.allow_incremental_sync ~= false
  end
end

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
    local orig_callback = vim.lsp.handlers[cb]
    local new_callback = function(idk, method, result)
      orig_callback(idk, method, result)
      vim.cmd('normal! zvzz')
    end
    vim.lsp.handlers[cb] = new_callback
  end

  -- Update loclist when diagnostics change
  local orig_callback = vim.lsp.handlers['textDocument/publishDiagnostics']
  local new_callback = function(a1, a2, params, client_id, bufnr, config)
    orig_callback(a1, a2, params, client_id, bufnr, config)
    M.on_update_diagnostics(bufnr)
  end
  vim.lsp.handlers['textDocument/publishDiagnostics'] = new_callback
  vim.cmd [[autocmd InsertLeave <buffer> lua require'init_lua'.on_update_diagnostics()]]

  vim.api.nvim_win_set_option(0, 'signcolumn', 'yes')
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
  mapper('n', 'gI', '<cmd>lua vim.lsp.buf.implementation()<CR>')
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

  mapper('n', '<space>', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')

  if config.cursor_highlight == true then
    vim.cmd [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]
  end

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")

  if config.autoformat then
    vim.cmd [[autocmd BufWritePre <buffer> lua require'init_lua'.autoformat()]]
  end

  aerial.on_attach(client)
end

M.autoformat = function()
  local pos = vim.fn.getcurpos()
  vim.lsp.buf.formatting_sync(nil, 1000)
  vim.fn.setpos('.', pos)
end

function on_attach_flow(client)
  require'flow'.on_attach(client)
  M.on_attach(client)
end

require'lspconfig'.bashls.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.gdscript.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.clangd.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.html.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.jsonls.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.omnisharp.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.pyright.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}


-- neovim doesn't support the full 3.16 spec, but latest rust-analyzer requires the following capabilities. 
-- Remove once implemented.
local default_capabilities = vim.lsp.protocol.make_client_capabilities()
default_capabilities.workspace.workspaceEdit = {
  normalizesLineEndings = true;
  changeAnnotationSupport = {
    groupsOnLabel = true;
  };
};
default_capabilities.textDocument.rename.prepareSupportDefaultBehavior = 1;
if vim.g.use_ultisnips == 0 then
  default_capabilities.textDocument.completion.completionItem.snippetSupport = true
end

require'lspconfig'.rust_analyzer.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
  capabilities = default_capabilities,
}
require'lspconfig'.tsserver.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
  root_dir = require 'lspconfig/util'.root_pattern("tsconfig.json", ".git");
}
require'lspconfig'.vimls.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.yamlls.setup{
  on_attach = M.on_attach,
  on_init = M.on_init,
}
require'lspconfig'.flow.setup{
  on_attach = on_attach_flow,
  on_init = M.on_init,
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
