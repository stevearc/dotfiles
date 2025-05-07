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

---@param items table[]
---@return boolean
local function all_item_locations_equal(items)
  if #items == 0 then
    return false
  end
  for i = 2, #items do
    local item = items[i]
    if item.bufnr ~= items[1].bufnr or item.filename ~= items[1].filename or item.lnum ~= items[1].lnum then
      return false
    end
  end
  return true
end

---@param yield fun(opts?: vim.lsp.ListOpts)
local function wrap_location_method(yield)
  return function()
    local from = vim.fn.getpos(".")
    yield({
      ---@param t vim.lsp.LocationOpts.OnList
      on_list = function(t)
        local curpos = vim.fn.getpos(".")
        if not vim.deep_equal(from, curpos) then
          -- We have moved the cursor since fetching locations, so abort
          return
        end

        if all_item_locations_equal(t.items) then
          -- Mostly copied from neovim source
          local item = t.items[1]
          local b = item.bufnr or vim.fn.bufadd(item.filename)

          -- Save position in jumplist
          vim.cmd("normal! m'")
          -- Push a new item into tagstack
          local tagname = vim.fn.expand("<cword>")
          local tagstack = { { tagname = tagname, from = from } }
          local winid = vim.api.nvim_get_current_win()
          vim.fn.settagstack(vim.fn.win_getid(winid), { items = tagstack }, "t")

          vim.bo[b].buflisted = true
          vim.api.nvim_win_set_buf(winid, b)
          pcall(vim.api.nvim_win_set_cursor, winid, { item.lnum, item.col - 1 })
          vim._with({ win = winid }, function()
            -- Open folds under the cursor
            vim.cmd("normal! zv")
          end)
        else
          vim.fn.setloclist(0, {}, " ", { title = t.title, items = t.items })
          if Snacks and Snacks.picker then
            Snacks.picker.loclist()
          else
            vim.cmd.lopen()
          end
        end
      end,
    })
  end
end

M.on_attach = function(client, bufnr)
  local function safemap(method, mode, key, rhs, desc)
    if client.server_capabilities[method] then
      vim.keymap.set(mode, key, rhs, { buffer = bufnr, desc = desc })
    end
  end

  if vim.fn.has("nvim-0.11") == 1 then
    safemap("definitionProvider", "n", "gd", wrap_location_method(vim.lsp.buf.definition), "[G]oto [D]efinition")
    safemap("declarationProvider", "n", "gD", wrap_location_method(vim.lsp.buf.declaration), "[G]oto [D]eclaration")
    safemap(
      "typeDefinitionProvider",
      "n",
      "gy",
      wrap_location_method(vim.lsp.buf.type_definition),
      "[G]oto T[y]pe Definition"
    )
    safemap(
      "implementationProvider",
      "n",
      "gI",
      wrap_location_method(vim.lsp.buf.implementation),
      "[G]oto [I]mplementation"
    )
  else
    safemap("definitionProvider", "n", "gd", cancelable("textDocument/definition"), "[G]oto [D]efinition")
    safemap("declarationProvider", "n", "gD", cancelable("textDocument/declaration"), "[G]oto [D]eclaration")
    safemap("typeDefinitionProvider", "n", "gy", cancelable("textDocument/typeDefinition"), "[G]oto T[y]pe Definition")
    safemap("implementationProvider", "n", "gI", cancelable("textDocument/implementation"), "[G]oto [I]mplementation")
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
local has_cmp_lsp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp_lsp then
  M.capabilities = vim.tbl_deep_extend("force", M.capabilities, cmp_nvim_lsp.default_capabilities())
end

return M
