local p = require("p")
local M = {}

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

M.on_attach = function(client, bufnr)
  local function safemap(method, mode, key, rhs, desc)
    if client.server_capabilities[method] then
      vim.keymap.set(mode, key, rhs, { buffer = bufnr, desc = desc })
    end
  end

  -- Standard LSP
  safemap("definitionProvider", "n", "gd", cancelable("textDocument/definition"), "[G]oto [D]efinition")
  safemap("declarationProvider", "n", "gD", cancelable("textDocument/declaration"), "[G]oto [D]eclaration")
  safemap("typeDefinitionProvider", "n", "gy", cancelable("textDocument/typeDefinition"), "[G]oto T[y]pe Definition")
  safemap("implementationProvider", "n", "gI", cancelable("textDocument/implementation"), "[G]oto [I]mplementation")
  safemap("referencesProvider", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", "[G]oto [R]eferences")
  -- Only map K if keywordprg is not ':help'
  if vim.fn.has("nvim-0.10") == 0 and vim.bo[bufnr].keywordprg ~= ":help" then
    safemap("hoverProvider", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", "Show hover information")
  end
  safemap("signatureHelpProvider", "i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Function signature help")
  safemap("codeActionProvider", "n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>", "[F]ind Code [A]ction")
  safemap(
    "codeActionProvider",
    "v",
    "<leader>fa",
    ":<C-U>lua vim.lsp.buf.range_code_action()<CR>",
    "[F]ind Code [A]ction"
  )
  safemap("renameProvider", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

  if client.server_capabilities.documentHighlightProvider and not client.name:match("sorbet$") then
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
p.require("cmp_nvim_lsp", function(cmp_nvim_lsp) M.capabilities = cmp_nvim_lsp.default_capabilities() end)

return M
