local stevearc = require("stevearc")
local projects = require("projects")

-- vim.lsp.set_log_level("debug")

require("lspsaga").init_lsp_saga()

if vim.g.nerd_font then
  vim.cmd([[
    sign define LspDiagnosticsSignError text=   numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
    sign define LspDiagnosticsSignWarning text=  numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
    sign define LspDiagnosticsSignInformation text=• numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
    sign define LspDiagnosticsSignHint text=• numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
  ]])
else
  vim.cmd([[
    sign define LspDiagnosticsSignError text=• numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
    sign define LspDiagnosticsSignWarning text=• numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
    sign define LspDiagnosticsSignInformation text=. numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
    sign define LspDiagnosticsSignHint text=. numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
  ]])
end

vim.g.aerial = {
  default_direction = "prefer_left",
  highlight_on_jump = 200,
  link_folds_to_tree = true,
  link_tree_to_folds = true,
  manage_folds = true,
  nerd_font = vim.g.nerd_font,
  -- filter_kind = {},
}

-- Make all the "jump" commands call zv after execution
local jump_callbacks = {
  "textDocument/declaration",
  "textDocument/definition",
  "textDocument/typeDefinition",
  "textDocument/implementation",
}
for _, cb in pairs(jump_callbacks) do
  local orig_callback = vim.lsp.handlers[cb]
  local new_callback = function(idk, method, result)
    orig_callback(idk, method, result)
    vim.cmd("normal! zv")
  end
  vim.lsp.handlers[cb] = new_callback
end

local function mapper(mode, key, result)
  vim.api.nvim_buf_set_keymap(0, mode, key, result, { noremap = true, silent = true })
end

local _ft_config = {
  ["_"] = {
    code_action = true,
    help = true,
  },
  vim = {
    help = false,
  },
  lua = {
    help = false,
  },
  cs = {
    code_action = false, -- TODO: this borks the omnisharp server
  },
}
local ft_config = setmetatable({}, {
  __index = function(_, key)
    if key == "javascriptreact" or key == "javascript.jsx" then
      key = "javascript"
    end
    if key == "typescriptreact" or key == "typescript.tsx" then
      key = "typescript"
    end
    local ret = _ft_config[key] or {}
    return setmetatable(ret, {
      __index = _ft_config["_"],
    })
  end,
})

local diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(...)
  local args = { ... }
  local client_id = args[4]
  local client = vim.lsp.get_client_by_id(client_id)
  if client.config.diagnostics ~= false then
    diagnostics_handler(...)
  end
end

vim.lsp.handlers["window/showMessage"] = function(_, _, result, client_id)
  local toast = require("toast")
  local message_type = result.type
  local message = result.message
  local client = vim.lsp.get_client_by_id(client_id)
  local client_name = client and client.name or string.format("id=%d", client_id)
  if not client then
    toast("LSP[" .. client_name .. "] client has shut down after sending the message", { type = "error" })
  end
  if message_type == vim.lsp.protocol.MessageType.Error then
    toast("LSP[" .. client_name .. "] " .. message, { type = "error" })
  else
    local message_type_name = vim.lsp.protocol.MessageType[message_type]
    local map = {
      Error = "error",
      Warning = "warn",
      Info = "info",
      Log = "info",
    }
    toast(string.format("LSP[%s] %s\n", client_name, message), { type = map[message_type_name] })
  end
  return result
end

function stevearc.on_update_diagnostics()
  local util = require("qf_helper.util")
  local config = require("qf_helper.config")
  local errors = vim.lsp.diagnostic.get_count(0, "Error")
  local warnings = vim.lsp.diagnostic.get_count(0, "Warning")
  if warnings + errors == 0 then
    vim.lsp.util.set_loclist({})
    if vim.fn.win_gettype() == "" then
      vim.cmd("lclose")
    end
  else
    vim.lsp.diagnostic.set_loclist({
      open_loclist = false,
      severity_limit = "Warning",
    })
    -- Resize the loclist
    if util.is_open("l") then
      local winid = vim.api.nvim_get_current_win()
      local height = math.max(config.l.min_height, math.min(config.l.max_height, errors + warnings))
      vim.cmd("lopen " .. height)
      vim.api.nvim_set_current_win(winid)
    end
  end
end

local on_attach = function(client)
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  local config = ft_config[ft] or {}

  local function safemap(method, mode, key, result)
    if client.resolved_capabilities[method] then
      mapper(mode, key, result)
    end
  end

  vim.cmd([[augroup LSPDiagnostics
  au!
  autocmd User LspDiagnosticsChanged lua require'stevearc'.on_update_diagnostics()
  augroup END]])

  vim.api.nvim_win_set_option(0, "signcolumn", "yes")

  -- Aerial
  if client.resolved_capabilities.document_symbol then
    mapper("n", "<leader>a", "<cmd>AerialToggle!<CR>")
    mapper("n", "{", "<cmd>AerialPrev<CR>")
    mapper("v", "{", "<cmd>AerialPrev<CR>")
    mapper("n", "}", "<cmd>AerialNext<CR>")
    mapper("v", "}", "<cmd>AerialNext<CR>")
    mapper("n", "[[", "<cmd>AerialPrevUp<CR>")
    mapper("v", "[[", "<cmd>AerialPrevUp<CR>")
    mapper("n", "]]", "<cmd>AerialNextUp<CR>")
    mapper("v", "]]", "<cmd>AerialNextUp<CR>")
  end

  -- Standard LSP
  safemap("goto_definition", "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  safemap("declaration", "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  safemap("type_definition", "n", "gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  safemap("implementation", "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  safemap("find_references", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  safemap("workspace_symbol", "n", "gs", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
  if config.help then
    safemap("hover", "n", "K", '<cmd>lua require("lspsaga.hover").render_hover_doc()<CR>')
  end
  if client.resolved_capabilities.signature_help then
    mapper("n", "<c-k>", '<cmd>lua require("lspsaga.signaturehelp").signature_help()<CR>')
    mapper("i", "<c-k>", '<cmd>lua require("lspsaga.signaturehelp").signature_help()<CR>')
  end
  if config.code_action then
    mapper("n", "<leader>p", '<cmd>lua require("lspsaga.codeaction").code_action()<CR>')
    mapper("v", "<leader>p", ':<C-U>lua require("lspsaga.codeaction").range_code_action()<CR>')
  end
  mapper("n", "<C-f>", '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(1)<CR>')
  mapper("n", "<C-b>", '<cmd>lua require("lspsaga.action").smart_scroll_with_saga(-1)<CR>')
  if client.resolved_capabilities.document_formatting then
    vim.cmd([[aug LspAutoformat
      au! * <buffer>
      autocmd BufWritePre <buffer> lua require'stevearc'.autoformat()
      aug END
    ]])
    mapper("n", "=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end
  safemap("document_range_formatting", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
  safemap("rename", "n", "<leader>r", '<cmd>lua require("lspsaga.rename").rename()<CR>')

  mapper("n", "<CR>", '<cmd>lua require"lspsaga.diagnostic".show_line_diagnostics()<CR>')

  if client.resolved_capabilities.document_highlight then
    vim.cmd([[autocmd CursorHold,CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]])
    vim.cmd([[autocmd CursorMoved,WinLeave <buffer> lua vim.lsp.buf.clear_references()]])
  end

  vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"

  require("lsp_signature").on_attach({
    use_lspsaga = true,
  })
  require("aerial").on_attach(client)
end

-- Configure the LSP servers
local lspservers = {
  "bashls",
  "clangd",
  "gdscript",
  "gopls",
  "html",
  "jsonls",
  "omnisharp",
  "vimls",
  "yamlls",
}
for _, server in ipairs(lspservers) do
  require("lspconfig")[server].setup({
    on_attach = on_attach,
  })
end
local function is_using_sqlalchemy()
  local util = require("lspconfig").util
  local path = util.path
  local setup = util.root_pattern("setup.cfg")(vim.fn.getcwd())
  if not setup then
    return false
  end
  for line in io.lines(path.join(setup, "setup.cfg")) do
    if string.find(line, "sqlalchemy.ext.mypy.plugin") or string.find(line, "sqlmypy") then
      return true
    end
  end
  return false
end
require("lspconfig").pyright.setup({
  on_attach = on_attach,
  diagnostics = not is_using_sqlalchemy(),
})
require("lspconfig").efm.setup({
  on_attach = on_attach,
  init_options = { documentFormatting = true },
  cmd = { "efm-langserver", "-logfile", "/tmp/efm.log", "-loglevel", "4" },
  filetypes = vim.tbl_keys(require("efmconfig")),
  root_dir = require("lspconfig").util.root_pattern(".git", "setup.py", "setup.cfg", "pyproject.toml", "package.json"),
  settings = {
    lintDebounce = 1000000000,
    languages = require("efmconfig"),
  },
})

-- neovim doesn't support the full 3.16 spec, but latest rust-analyzer requires the following capabilities.
-- Remove once implemented.
local default_capabilities = vim.lsp.protocol.make_client_capabilities()
default_capabilities.workspace.workspaceEdit = {
  normalizesLineEndings = true,
  changeAnnotationSupport = {
    groupsOnLabel = true,
  },
}
default_capabilities.textDocument.rename.prepareSupportDefaultBehavior = 1
default_capabilities.textDocument.completion.completionItem.snippetSupport = true

require("lspconfig").rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = default_capabilities,
})
require("lspconfig").tsserver.setup({
  on_attach = function(client)
    local format = not projects[0].ts_prettier_format
    client.resolved_capabilities.document_formatting = format
    client.resolved_capabilities.document_range_formatting = format
    on_attach(client)
  end,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
})
require("lspconfig").flow.setup({
  on_attach = function(client)
    require("flow").on_attach(client)
    on_attach(client)
  end,
  cmd = { "flow", "lsp", "--lazy" },
  settings = {
    flow = {
      coverageSeverity = "warn",
      showUncovered = true,
      stopFlowOnExit = false,
      useBundledFlow = false,
    },
  },
})
local home = vim.fn.expand("$HOME")
local sumneko_root_path = home .. "/.local/share/nvim/language-servers/lua-language-server"
local sumneko_binary = sumneko_root_path .. "/bin/Linux/lua-language-server"
require("lspconfig").sumneko_lua.setup({
  cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = vim.split(package.path, ";"),
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
        },
      },
    },
  },

  on_attach = on_attach,
})

require("lspconfig").sorbet.setup({
  cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
  on_attach = on_attach,
})

-- Since we missed the FileType event when this runs on vim start, we should
-- manually make sure that LSP starts on the first file opened.
vim.defer_fn(function()
  vim.api.nvim_command("LspStart")
end, 10)
