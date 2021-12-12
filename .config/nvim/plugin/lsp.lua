-- vim.lsp.set_log_level("debug")

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

if vim.g.nerd_font then
  vim.cmd([[
      sign define DiagnosticSignError text=   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=• numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=• numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
else
  vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=. numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=. numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
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

local ft_config = {
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
local diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, context, config)
  local client = vim.lsp.get_client_by_id(context.client_id)
  if client.config.diagnostics ~= false then
    diagnostics_handler(err, result, context, config)
  end
end

vim.lsp.handlers["window/showMessage"] = function(_err, result, context, _config)
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
end

function stevearc.on_update_diagnostics()
  local util = require("qf_helper.util")
  local config = require("qf_helper.config")
  local total = vim.tbl_count(vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.W } }))
  if total == 0 then
    vim.lsp.util.set_loclist({})
    if vim.fn.win_gettype() == "" then
      vim.cmd("silent! lclose")
    end
  else
    vim.diagnostic.setloclist({
      open = false,
      severity = {
        min = vim.diagnostic.severity.W,
      },
    })
    -- Resize the loclist
    if util.is_open("l") then
      local winid = vim.api.nvim_get_current_win()
      local height = math.max(config.l.min_height, math.min(config.l.max_height, total))
      vim.cmd("lopen " .. height)
      vim.api.nvim_set_current_win(winid)
    end
  end
end

local function adjust_formatting_capabilities(client, bufnr)
  local info = require("null-ls.info")
  local null_ls_client = require("null-ls.client").get_client()
  if not null_ls_client or not vim.lsp.buf_is_attached(bufnr, null_ls_client.id) then
    return
  end
  local active_sources = info.get_active_sources(bufnr)
  local formatters = active_sources.NULL_LS_FORMATTING
  local null_ls_formats = formatters and not vim.tbl_isempty(formatters)
  if client.id == null_ls_client.id then
    -- We're attaching a null-ls client. If it has a formatter, disable
    -- formatting on all prior clients
    if null_ls_formats then
      local clients = vim.lsp.buf_get_clients(bufnr)
      for _, other_client in ipairs(clients) do
        if other_client.id ~= client.id then
          other_client.resolved_capabilities.document_formatting = false
          other_client.resolved_capabilities.document_range_formatting = false
        end
      end
    end
  elseif null_ls_formats then
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end
end

vim.cmd([[augroup LSPDiagnostics
  au!
  autocmd DiagnosticChanged lua stevearc.on_update_diagnostics()
  augroup END]])

local on_attach = function(client, bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local config = ft_config[ft] or {}

  adjust_formatting_capabilities(client, bufnr)

  local function mapper(mode, key, result)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, result, { noremap = true, silent = true })
  end

  local function safemap(method, mode, key, result)
    if client.resolved_capabilities[method] then
      mapper(mode, key, result)
    end
  end

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(winid) == bufnr then
      vim.api.nvim_win_set_option(winid, "signcolumn", "yes")
    end
  end

  -- Standard LSP
  safemap("goto_definition", "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  safemap("declaration", "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  safemap("type_definition", "n", "gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  safemap("implementation", "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  safemap("find_references", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  if config.help ~= false then
    safemap("hover", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  end
  if client.resolved_capabilities.signature_help then
    mapper("i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  end
  if config.code_action ~= false then
    mapper("n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    mapper("v", "<leader>fa", ":<C-U>lua vim.lsp.buf.range_code_action()<CR>")
  end
  if client.resolved_capabilities.document_formatting then
    vim.cmd([[aug LspAutoformat
      au! * <buffer>
      autocmd BufWritePre <buffer> lua stevearc.autoformat()
      aug END
    ]])
    mapper("n", "=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end
  safemap("document_range_formatting", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
  safemap("rename", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

  mapper("n", "<CR>", "<cmd>lua vim.diagnostic.open_float(0, {scope='line', border='rounded'})<CR>")

  if client.resolved_capabilities.document_highlight then
    vim.cmd([[autocmd CursorHold,CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]])
    vim.cmd([[autocmd CursorMoved,WinLeave <buffer> lua vim.lsp.buf.clear_references()]])
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  require("lsp_signature").on_attach({}, bufnr)
  require("aerial").on_attach(client, bufnr)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

-- Configure the LSP servers
local lspservers = {
  "bashls",
  "clangd",
  "cssls",
  "gdscript",
  "gopls",
  "html",
  "omnisharp",
  "rust_analyzer",
  "vimls",
}
for _, server in ipairs(lspservers) do
  require("lspconfig")[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end
require("lspconfig").yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    yaml = {
      schemas = require("schemastore").json.schemas(),
    },
  },
})
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
  -- pyright is real noisy when we're using sqlalchemy
  diagnostics = not is_using_sqlalchemy(),
})
require("lspconfig").jsonls.setup({
  filetypes = { "json", "jsonc", "json5" },
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
    },
  },
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
  on_attach = on_attach,
})
require("lspconfig").flow.setup({
  capabilities = capabilities,
  root_dir = function(fname)
    local util = require("lspconfig.util")
    -- Disable flow when a typescript project is detected
    if util.root_pattern("tsconfig.json")(fname) then
      return nil
    end
    return util.root_pattern(".flowconfig")(fname)
  end,
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
local sumneko_root_path = os.getenv("HOME") .. "/.local/share/nvim/language-servers/lua-language-server"
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
          [os.getenv("VIMRUNTIME") .. "/lua"] = true,
          [os.getenv("VIMRUNTIME") .. "/lua/vim/lsp"] = true,
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

require("null-ls").setup(vim.tbl_extend("keep", {
  capabilities = capabilities,
  root_dir = function(fname)
    local util = require("lspconfig.util")
    return util.root_pattern(".git", "Makefile", "setup.py", "setup.cfg", "pyproject.toml", "package.json")(fname)
      or util.path.dirname(fname)
  end,
  on_attach = on_attach,
}, require("nullconfig")))
