local M = {}

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

return M
