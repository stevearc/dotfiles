local lazy = require("lazy")
local M = {}

local function adjust_formatting_capabilities(client, bufnr)
  if not pcall(require, "null-ls") then
    return
  end
  local sources = require("null-ls.sources")
  local methods = require("null-ls.methods")
  local null_ls_client = require("null-ls.client").get_client()
  if not null_ls_client or not vim.lsp.buf_is_attached(bufnr, null_ls_client.id) then
    return
  end
  local formatters = sources.get_available(vim.api.nvim_buf_get_option(bufnr, "filetype"), methods.FORMATTING)
  if vim.tbl_isempty(formatters) then
    return
  end
  if client.id == null_ls_client.id then
    -- We're attaching a null-ls client. If it has a formatter, disable
    -- formatting on all prior clients
    local clients = vim.lsp.buf_get_clients(bufnr)
    for _, other_client in ipairs(clients) do
      if other_client.id ~= client.id then
        other_client.server_capabilities.documentFormattingProvider = nil
        other_client.server_capabilities.documentRangeFormattingProvider = nil
      end
    end
  else
    client.server_capabilities.documentFormattingProvider = nil
    client.server_capabilities.documentRangeFormattingProvider = nil
  end
end

M.save_win_positions = function(bufnr)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local win_positions = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(winid) == bufnr then
      vim.api.nvim_win_call(winid, function()
        local view = vim.fn.winsaveview()
        table.insert(win_positions, { winid, view })
      end)
    end
  end

  return function()
    for _, pair in ipairs(win_positions) do
      local winid, view = unpack(pair)
      vim.api.nvim_win_call(winid, function()
        pcall(vim.fn.winrestview, view)
      end)
    end
  end
end

local function cancelable(method)
  return function()
    local params = vim.lsp.util.make_position_params()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.lsp.buf_request(0, method, params, function(...)
      local new_cursor = vim.api.nvim_win_get_cursor(0)
      if vim.api.nvim_get_current_buf() == bufnr and vim.deep_equal(cursor, new_cursor) then
        vim.lsp.handlers[method](...)
      end
    end)
  end
end

local autoformat_group = vim.api.nvim_create_augroup("LspAutoformat", { clear = true })
M.on_attach = function(client, bufnr)
  adjust_formatting_capabilities(client, bufnr)

  local function safemap(method, mode, key, rhs, desc)
    if client.server_capabilities[method] then
      vim.keymap.set(mode, key, rhs, { desc = desc })
    end
  end

  -- Standard LSP
  safemap("definitionProvider", "n", "gd", cancelable("textDocument/definition"), "[G]oto [D]efinition")
  safemap("declarationProvider", "n", "gD", cancelable("textDocument/declaration"), "[G]oto [D]eclaration")
  safemap("typeDefinitionProvider", "n", "<leader>D", cancelable("textDocument/typeDefinition"), "Type [D]efinition")
  safemap("implementationProvider", "n", "gi", cancelable("textDocument/implementation"), "[G]oto [I]mplementation")
  safemap("referencesProvider", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
  -- Only map K if keywordprg is not ':help'
  if vim.api.nvim_buf_get_option(bufnr, "keywordprg") ~= ":help" then
    safemap("hoverProvider", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", "Show hover information")
  end
  safemap("signatureHelpProvider", "i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Function signature help")
  -- This crashed omnisharp last I checked
  if client.name ~= "omnisharp" then
    safemap("codeActionProvider", "n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>", "[F]ind Code [A]ction")
    safemap(
      "codeActionProvider",
      "v",
      "<leader>fa",
      ":<C-U>lua vim.lsp.buf.range_code_action()<CR>",
      "[F]ind Code [A]ction"
    )
  end
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = autoformat_group,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        safe_require("autoformat").format()
      end,
      buffer = bufnr,
      group = autoformat_group,
    })
    vim.keymap.set("n", "=", function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = bufnr })
  end
  safemap("documentRangeFormattingProvider", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
  safemap("renameProvider", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

  if client.server_capabilities.documentHighlightProvider and not string.match(client.name, "sorbet$") then
    vim.api.nvim_create_autocmd({ "CursorHold" }, {
      desc = "LSP highlight document word",
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "WinLeave" }, {
      desc = "Clear LSP cursor word highlights",
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

---@param name string
---@param config nil|table
M.safe_setup = function(name, config)
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    return
  end
  config = config or {}

  local has_config, server_config = pcall(require, "lspconfig.server_configurations." .. name)
  if has_config then
    local cmd = config.cmd or server_config.default_config.cmd
    if type(cmd) == "table" and type(cmd[1]) == "string" then
      local exe = cmd[1]
      if vim.fn.executable(exe) == 0 then
        return
      end
    end
  end
  lspconfig[name].setup(vim.tbl_extend("keep", config or {}, {
    capabilities = M.capabilities,
  }))
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
lazy.load("cmp-nvim-lsp").require("cmp_nvim_lsp", function(cmp_nvim_lsp)
  M.capabilities = cmp_nvim_lsp.default_capabilities()
end)

return M
