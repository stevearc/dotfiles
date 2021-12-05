local stevearc = require("stevearc")
local projects = require("projects")
local GENERAL_DIAGNOSTICS = vim.diagnostic ~= nil

-- vim.lsp.set_log_level("debug")

if vim.diagnostic then
  vim.diagnostic.config({
    float = {
      source = "always",
    },
    virtual_text = {
      severity = { min = vim.diagnostic.severity.W },
      source = "if_many",
    },
    severity_sort = true,
  })
end

if vim.g.nerd_font then
  -- Names changed in 0.6
  if vim.diagnostic == nil then
    vim.cmd([[
      sign define LspDiagnosticsSignError text=   numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
      sign define LspDiagnosticsSignWarning text=  numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
      sign define LspDiagnosticsSignInformation text=• numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
      sign define LspDiagnosticsSignHint text=• numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
    ]])
  else
    vim.cmd([[
      sign define DiagnosticSignError text=   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=• numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=• numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
  end
else
  if vim.diagnostic == nil then
    vim.cmd([[
      sign define LspDiagnosticsSignError text=• numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
      sign define LspDiagnosticsSignWarning text=• numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
      sign define LspDiagnosticsSignInformation text=. numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
      sign define LspDiagnosticsSignHint text=. numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
    ]])
  else
    vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=. numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=. numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
  end
end

-- callback args changed in Neovim 0.6. See:
-- https://github.com/neovim/neovim/pull/15504
local function mk_handler(fn)
  return function(...)
    local config_or_client_id = select(4, ...)
    local is_new = type(config_or_client_id) ~= "number"
    if is_new then
      fn(...)
    else
      local err = select(1, ...)
      local method = select(2, ...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      local bufnr = select(5, ...)
      local config = select(6, ...)
      fn(err, result, { method = method, client_id = client_id, bufnr = bufnr }, config)
    end
  end
end

-- Make all the "jump" commands call zv after execution
local jump_callbacks = {
  "textDocument/declaration",
  "textDocument/definition",
  "textDocument/typeDefinition",
  "textDocument/implementation",
}
for _, cb in pairs(jump_callbacks) do
  local orig_callback = vim.lsp.handlers[cb]
  local new_callback = function(...)
    orig_callback(...)
    vim.cmd("normal! zv")
  end
  vim.lsp.handlers[cb] = new_callback
end

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

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
  local config_or_client_id = select(4, ...)
  local is_new = type(config_or_client_id) ~= "number"
  local client_id
  if is_new then
    local context = select(3, ...)
    client_id = context.client_id
  else
    client_id = select(4, ...)
  end
  local client = vim.lsp.get_client_by_id(client_id)
  if client.config.diagnostics ~= false then
    diagnostics_handler(...)
  end
end

vim.lsp.handlers["window/showMessage"] = mk_handler(function(_err, result, context, _config)
  local client_id = context.client_id
  local message_type = result.type
  local message = result.message
  local client = vim.lsp.get_client_by_id(client_id)
  local client_name = client and client.name or string.format("id=%d", client_id)
  if not client then
    vim.notify("LSP[" .. client_name .. "] client has shut down after sending the message", vim.log.levels.ERROR)
  end
  if message_type == vim.lsp.protocol.MessageType.Error then
    vim.notify("LSP[" .. client_name .. "] " .. message, vim.log.levels.ERROR)
  else
    local message_type_name = vim.lsp.protocol.MessageType[message_type]
    local map = {
      Error = vim.log.levels.ERROR,
      Warning = vim.log.levels.WARN,
      Info = vim.log.levels.INFO,
      Log = vim.log.levels.DEBUG,
    }
    vim.notify(string.format("LSP[%s] %s\n", client_name, message), map[message_type_name])
  end
  return result
end)

function stevearc.on_update_diagnostics()
  local util = require("qf_helper.util")
  local config = require("qf_helper.config")
  local total
  if vim.diagnostic == nil then
    local errors = vim.lsp.diagnostic.get_count(0, "Error")
    local warnings = vim.lsp.diagnostic.get_count(0, "Warning")
    total = errors + warnings
  else
    total = vim.tbl_count(vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.W } }))
  end
  if total == 0 then
    vim.lsp.util.set_loclist({})
    if vim.fn.win_gettype() == "" then
      vim.cmd("silent! lclose")
    end
  else
    if vim.diagnostic == nil then
      vim.lsp.diagnostic.set_loclist({
        open = false,
        severity_limit = "Warning",
        -- nvim 0.5
        open_loclist = false,
      })
    else
      vim.diagnostic.setloclist({
        open = false,
        severity = {
          min = vim.diagnostic.severity.W,
        },
      })
    end
    -- Resize the loclist
    if util.is_open("l") then
      local winid = vim.api.nvim_get_current_win()
      local height = math.max(config.l.min_height, math.min(config.l.max_height, total))
      vim.cmd("lopen " .. height)
      vim.api.nvim_set_current_win(winid)
    end
  end
end

local on_attach = function(client, bufnr)
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  local config = ft_config[ft] or {}

  local function safemap(method, mode, key, result)
    if client.resolved_capabilities[method] then
      mapper(mode, key, result)
    end
  end

  local autocmd = GENERAL_DIAGNOSTICS and "DiagnosticsChanged" or "LspDiagnosticsChanged"
  vim.cmd(string.format(
    [[augroup LSPDiagnostics
  au!
  autocmd User %s lua require'stevearc'.on_update_diagnostics()
  augroup END]],
    autocmd
  ))

  vim.api.nvim_win_set_option(0, "signcolumn", "yes")

  -- Standard LSP
  safemap("goto_definition", "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  safemap("declaration", "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  safemap("type_definition", "n", "gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  safemap("implementation", "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  safemap("find_references", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  if config.help then
    safemap("hover", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  end
  if client.resolved_capabilities.signature_help then
    mapper("i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  end
  if config.code_action then
    mapper("n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    mapper("v", "<leader>fa", ":<C-U>lua vim.lsp.buf.range_code_action()<CR>")
  end
  if client.resolved_capabilities.document_formatting then
    vim.cmd([[aug LspAutoformat
      au! * <buffer>
      autocmd BufWritePre <buffer> lua require'stevearc'.autoformat()
      aug END
    ]])
    mapper("n", "=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end
  safemap("document_range_formatting", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
  safemap("rename", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

  if vim.diagnostic == nil then
    mapper("n", "<CR>", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({border='rounded'})<CR>")
  else
    mapper("n", "<CR>", "<cmd>lua vim.diagnostic.open_float(0, {scope='line', border='rounded'})<CR>")
  end

  if client.resolved_capabilities.document_highlight then
    vim.cmd([[autocmd CursorHold,CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]])
    vim.cmd([[autocmd CursorMoved,WinLeave <buffer> lua vim.lsp.buf.clear_references()]])
  end

  vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"

  require("lsp_signature").on_attach({}, bufnr)
  require("aerial").on_attach(client, bufnr)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

-- Configure the LSP servers
local lspservers = {
  "bashls",
  "clangd",
  "gdscript",
  "gopls",
  "html",
  "cssls",
  "omnisharp",
  "vimls",
  "yamlls",
}
for _, server in ipairs(lspservers) do
  require("lspconfig")[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end
local function is_using_sqlalchemy()
  local util = require("lspconfig").util
  local path = util.path
  local setup = util.root_pattern("setup.cfg")(vim.loop.cwd())
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
  capabilities = capabilities,
  on_attach = on_attach,
  diagnostics = not is_using_sqlalchemy(),
})
require("lspconfig").jsonls.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    local util = require("lspconfig.util")
    local filename = vim.api.nvim_buf_get_name(bufnr)
    if vim.fn.executable("prettier") ~= 0 or util.root_pattern("package.json")(filename) then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
    on_attach(client, bufnr)
  end,
})
if not vim.g.null_ls then
  require("lspconfig").efm.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    init_options = { documentFormatting = true },
    cmd = { "efm-langserver", "-logfile", "/tmp/efm.log", "-loglevel", "4" },
    filetypes = vim.tbl_keys(require("efmconfig")),
    root_dir = require("lspconfig").util.root_pattern(
      ".git",
      "setup.py",
      "setup.cfg",
      "pyproject.toml",
      "package.json"
    ),
    settings = {
      lintDebounce = 1000000000,
      languages = require("efmconfig"),
    },
  })
end

require("lspconfig").rust_analyzer.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
require("lspconfig").tsserver.setup({
  capabilities = capabilities,
  root_dir = function(fname)
    local util = require("lspconfig.util")
    -- Disable tsserver when a flow project is detected
    if util.root_pattern(".flowconfig")(fname) then
      return nil
    end
    return util.root_pattern("tsconfig.json")(fname)
      or util.root_pattern("package.json", "jsconfig.json", ".git")(fname)
  end,
  on_attach = function(client, bufnr)
    local format = not projects[0].ts_prettier_format
    client.resolved_capabilities.document_formatting = format
    client.resolved_capabilities.document_range_formatting = format
    on_attach(client, bufnr)
  end,
})
require("lspconfig").flow.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    require("flow").on_attach(client, bufnr)
    on_attach(client, bufnr)
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
  capabilities = capabilities,
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
  capabilities = capabilities,
  cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
  on_attach = on_attach,
})

if vim.g.null_ls then
  require("null-ls").config(require("nullconfig"))
  require("lspconfig")["null-ls"].setup({
    capabilities = capabilities,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      return util.root_pattern(".git", "Makefile", "setup.py", "setup.cfg", "pyproject.toml", "package.json")(fname)
        or util.path.dirname(fname)
    end,
    on_attach = on_attach,
  })
end

-- Since we missed the FileType event when this runs on vim start, we should
-- manually make sure that LSP starts on the first file opened.
vim.defer_fn(function()
  vim.api.nvim_command("LspStart")
end, 10)
