local stevearc = require'stevearc'

-- vim.lsp.set_log_level('debug')

require('lspsaga').init_lsp_saga()

if vim.g.nerd_font then
  vim.cmd[[sign define LspDiagnosticsSignError text=   numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError]]
  vim.cmd[[sign define LspDiagnosticsSignWarning text=  numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning]]
  vim.cmd[[sign define LspDiagnosticsSignInformation text=• numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation]]
  vim.cmd[[sign define LspDiagnosticsSignHint text=• numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint]]
else
  vim.cmd[[sign define LspDiagnosticsSignError text=• numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError]]
  vim.cmd[[sign define LspDiagnosticsSignWarning text=• numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning]]
  vim.cmd[[sign define LspDiagnosticsSignInformation text=. numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation]]
  vim.cmd[[sign define LspDiagnosticsSignHint text=. numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint]]
end

vim.g.aerial = {
  default_direction = 'prefer_left',
  highlight_on_jump = 200,
  link_folds_to_tree = true,
  manage_folds = true,
  nerd_font = vim.g.nerd_font,
  -- filter_kind = {},
}

-- Make all the "jump" commands call zv after execution
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
    vim.cmd('normal! zv')
  end
  vim.lsp.handlers[cb] = new_callback
end

local mapper = function(mode, key, result)
  vim.api.nvim_buf_set_keymap(0, mode, key, result, {noremap = true, silent = true})
end

local _ft_config = {
  ['_'] = {
    allow_incremental_sync = true,
    autoformat = false,
    code_action = true,
    cursor_highlight = true,
    help = true,
  },
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
  typescript = {
    autoformat = true,
  },
}
local ft_config = setmetatable({}, {
  __index = function(_, key)
    if key == 'javascriptreact' or key == 'javascript.jsx' then
      key = 'javascript'
    end
    if key == 'typescriptreact' or key == 'typescript.jsx' then
      key = 'typescript'
    end
    local ret = _ft_config[key] or {}
    return setmetatable(ret, {
      __index = _ft_config['_']
    })
  end
})

function stevearc:on_update_diagnostics()
  local util = require 'qf_helper.util'
  local errors = vim.lsp.diagnostic.get_count(0, "Error")
  local warnings = vim.lsp.diagnostic.get_count(0, "Warning")
  if warnings + errors == 0 then
    vim.lsp.util.set_loclist({})
    vim.cmd('lclose')
  else
    vim.lsp.diagnostic.set_loclist{
      open_loclist = false,
      severity_limit = "Warning",
    }
    -- Resize the loclist
    if util.is_open('l') then
      local winid = vim.fn.win_getid()
      local height = math.max(vim.g.qf_min_height, math.min(vim.g.qf_max_height, errors + warnings))
      vim.cmd('lopen '..height)
      vim.fn.win_gotoid(winid)
    end
  end
end

function stevearc:autoformat()
  local pos = vim.fn.getcurpos()
  vim.lsp.buf.formatting_sync(nil, 1000)
  vim.fn.setpos('.', pos)
end

local on_init = function(client)
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local config = ft_config[ft] or {}

  client.config.flags = {}
  if client.config.flags then
    client.config.flags.allow_incremental_sync = config.allow_incremental_sync
  end
end

local on_attach = function(client)
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local config = ft_config[ft] or {}

  vim.cmd [[autocmd User LspDiagnosticsChanged lua require'stevearc'.on_update_diagnostics()]]

  vim.api.nvim_win_set_option(0, 'signcolumn', 'yes')

  -- Aerial
  mapper('n', '<leader>a', '<cmd>AerialToggle!<CR>')
  mapper('n', '{', '<cmd>AerialPrev<CR>')
  mapper('v', '{', '<cmd>AerialPrev<CR>')
  mapper('n', '}', '<cmd>AerialNext<CR>')
  mapper('v', '}', '<cmd>AerialNext<CR>')
  mapper('n', '[[', '<cmd>AerialPrevUp<CR>')
  mapper('v', '[[', '<cmd>AerialPrevUp<CR>')
  mapper('n', ']]', '<cmd>AerialNextUp<CR>')
  mapper('v', ']]', '<cmd>AerialNextUp<CR>')

  -- Standard LSP
  mapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  mapper('n', 'tgd', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  mapper('n', 'gI', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  mapper('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  mapper('n', 'gs', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  if config.help then
    mapper('n', 'K', '<cmd>lua require("lspsaga.hover").render_hover_doc()<CR>')
    mapper('n', '<C-j>', '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(1)<CR>')
    mapper('n', '<C-k>', '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(-1)<CR>')
  end
  mapper('n', '<c-k>', '<cmd>lua require("lspsaga.signaturehelp").signature_help()<CR>')
  mapper('i', '<c-k>', '<cmd>lua require("lspsaga.signaturehelp").signature_help()<CR>')
  if config.code_action then
    mapper('n', '<leader>p', '<cmd>lua require("lspsaga.codeaction").code_action()<CR>')
    mapper('v', '<leader>p', ':<C-U>lua require("lspsaga.codeaction").range_code_action()<CR>')
  end
  mapper('n', '<C-f>', '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(1)<CR>')
  mapper('n', '<C-b>', '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(-1)<CR>')
  mapper('n', '=', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('v', '=', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')
  mapper('n', '<leader>r', '<cmd>lua require("lspsaga.rename").rename()<CR>')

  mapper('n', '<CR>', '<cmd>lua require"lspsaga.diagnostic".show_line_diagnostics()<CR>')

  if config.cursor_highlight then
    vim.cmd [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
    vim.cmd [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]
  end

  vim.bo.omnifunc = 'v:lua.vim.lsp.omnifunc'

  if config.autoformat then
    vim.cmd [[autocmd BufWritePre <buffer> lua require'stevearc'.autoformat()]]
  end

  require'lsp_signature'.on_attach({
    use_lspsaga = true,
  })
  require 'aerial'.on_attach(client)
end

-- Configure the LSP servers
require'lspconfig'.bashls.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.gdscript.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.clangd.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.html.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.jsonls.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.omnisharp.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.pyright.setup{
  on_attach = on_attach,
  on_init = on_init,
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
  on_attach = on_attach,
  on_init = on_init,
  capabilities = default_capabilities,
}
require'lspconfig'.tsserver.setup{
  on_attach = on_attach,
  on_init = on_init,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
  root_dir = require 'lspconfig/util'.root_pattern("tsconfig.json", ".git");
}
require'lspconfig'.vimls.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.gopls.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.yamlls.setup{
  on_attach = on_attach,
  on_init = on_init,
}
require'lspconfig'.flow.setup{
  on_attach = function (client)
    require'flow'.on_attach(client)
    on_attach(client)
  end,
  on_init = on_init,
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
local home = vim.fn.expand('$HOME')
local sumneko_root_path = home .. '/.local/share/nvim/language-servers/lua-language-server'
local sumneko_binary = sumneko_root_path.."/bin/Linux/lua-language-server"
require'lspconfig'.sumneko_lua.setup({
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"};
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';'),
      },
      diagnostics = {
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        },
      },
    }
  },

  on_attach = on_attach,
  on_init = on_init,
})

-- Since we missed the FileType event when this runs on vim start, we should
-- manually make sure that LSP starts on the first file opened.
vim.defer_fn(function()
  vim.api.nvim_command("LspStart")
end, 10)
