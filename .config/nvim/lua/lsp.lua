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
        -- For backwards compatibility. Remove in neovim 0.7.1
        if rawget(other_client, "resolved_capabilities") then
          other_client.resolved_capabilities.document_formatting = false
          other_client.resolved_capabilities.document_range_formatting = false
        end
      end
    end
  else
    client.server_capabilities.documentFormattingProvider = nil
    client.server_capabilities.documentRangeFormattingProvider = nil
    -- For backwards compatibility. Remove in neovim 0.7.1
    if rawget(client, "resolved_capabilities") then
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
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

local autoformat_group = vim.api.nvim_create_augroup("LspAutoformat", { clear = true })
M.on_attach = function(client, bufnr)
  adjust_formatting_capabilities(client, bufnr)

  local function mapper(mode, key, result)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, result, { noremap = true, silent = true })
  end

  local function safemap(method, mode, key, result)
    if client.server_capabilities[method] then
      mapper(mode, key, result)
    end
  end

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      vim.api.nvim_win_set_option(winid, "signcolumn", "yes")
    end
  end

  -- Standard LSP
  safemap("definitionProvider", "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  safemap("declarationProvider", "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  safemap("typeDefinitionProvider", "n", "gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  safemap("implementationProvider", "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  safemap("referencesProvider", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  -- Only map K if keywordprg is not ':help'
  if vim.api.nvim_buf_get_option(bufnr, "keywordprg") ~= ":help" then
    safemap("hoverProvider", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  end
  safemap("signatureHelpProvider", "i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  -- This crashed omnisharp last I checked
  if client.name ~= "omnisharp" then
    safemap("codeActionProvider", "n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    safemap("codeActionProvider", "v", "<leader>fa", ":<C-U>lua vim.lsp.buf.range_code_action()<CR>")
  end
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = autoformat_group,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        stevearc.autoformat()
      end,
      buffer = bufnr,
      group = autoformat_group,
    })
    vim.keymap.set("n", "=", function()
      if vim.lsp.buf.format then
        vim.lsp.buf.format({ async = true })
      else
        vim.lsp.buf.formatting()
      end
    end, { buffer = bufnr })
  end
  safemap("documentRangeFormattingProvider", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
  safemap("renameProvider", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

  mapper("n", "<CR>", "<cmd>lua vim.diagnostic.open_float(0, {scope='line', border='rounded'})<CR>")

  if client.server_capabilities.documentHighlightProvider and client.name ~= "sorbet" then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "WinLeave" }, {
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  safe_require("aerial").on_attach(client, bufnr)
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
safe_require("cmp_nvim_lsp", function(cmp_nvim_lsp)
  M.capabilities = cmp_nvim_lsp.update_capabilities(M.capabilities)
end)

return M
