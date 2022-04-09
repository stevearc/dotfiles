local M = {}

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
        other_client.resolved_capabilities.document_formatting = false
        other_client.resolved_capabilities.document_range_formatting = false
      end
    end
  else
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end
end

M.on_attach = function(client, bufnr)
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
  safemap("signature_help", "i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  if config.code_action ~= false then
    safemap("code_action", "n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    safemap("code_action", "v", "<leader>fa", ":<C-U>lua vim.lsp.buf.range_code_action()<CR>")
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
    vim.cmd([[aug LspShowReferences
        au! * <buffer>
        autocmd CursorHold,CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved,WinLeave <buffer> lua vim.lsp.buf.clear_references()
        aug END
      ]])
  end

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  safe_require("aerial").on_attach(client, bufnr)
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
safe_require("cmp_nvim_lsp", function(cmp_nvim_lsp)
  M.capabilities = cmp_nvim_lsp.update_capabilities(M.capabilities)
end)

return M
