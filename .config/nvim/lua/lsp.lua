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

  if vim.fn.has("nvim-0.11") == 0 then
    safemap(
      "referencesProvider",
      "n",
      "grr",
      "<cmd>lua vim.lsp.buf.references()<CR>",
      "[G]oto [R]eferences [R]ight now"
    )
    safemap(
      "signatureHelpProvider",
      "i",
      "<c-s>",
      "<cmd>lua vim.lsp.buf.signature_help()<CR>",
      "Function signature help"
    )
    safemap("codeActionProvider", "n", "gra", "<cmd>lua vim.lsp.buf.code_action()<CR>", "[G]o [R]efactor code [A]ction")
    safemap(
      "codeActionProvider",
      "v",
      "gra",
      ":<C-U>lua vim.lsp.buf.range_code_action()<CR>",
      "[G]o [R]efactor code [A]ction"
    )
    safemap("renameProvider", "n", "grn", "<cmd>lua vim.lsp.buf.rename()<CR>", "[G]o [R]e[n]ame")
  end

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

  vim.keymap.set(
    "n",
    "gtt",
    function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
    { desc = "Inlay hint [T]ype [T]oggle" }
  )
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
