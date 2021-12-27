require("luasnip.loaders.from_vscode").lazy_load()
vim.api.nvim_set_keymap("s", "<Tab>", "<Plug>luasnip-jump-next", {})
vim.api.nvim_set_keymap("s", "<C-h>", "<Plug>luasnip-jump-prev", {})
vim.api.nvim_set_keymap("s", "<C-l>", "<Plug>luasnip-jump-next", {})
vim.api.nvim_set_keymap("i", "<C-k>", "<Plug>luasnip-prev-choice", {})
vim.api.nvim_set_keymap("i", "<C-j>", "<Plug>luasnip-next-choice", {})
vim.api.nvim_set_keymap("s", "<C-k>", "<Plug>luasnip-prev-choice", {})
vim.api.nvim_set_keymap("s", "<C-j>", "<Plug>luasnip-next-choice", {})
vim.cmd([[
  aug ClearLuasnipSession
    au!
    " Can't use InsertLeave here because that fires when we go to select mode
    au CursorHold * silent LuaSnipUnlinkCurrent
  aug END
  ]])

vim.api.nvim_set_keymap("i", "<C-h>", "v:lua.stevearc.left_in_insert()", { expr = true })
vim.api.nvim_set_keymap("i", "<C-l>", "v:lua.stevearc.right_in_insert()", { expr = true })
function stevearc.left_in_insert()
  if require("luasnip").get_active_snip() then
    require("luasnip").jump(-1)
    return ""
  else
    return vim.api.nvim_replace_termcodes("<Left>", true, true, true)
  end
end
function stevearc.right_in_insert()
  if require("luasnip").get_active_snip() then
    require("luasnip").jump(1)
    return ""
  else
    return vim.api.nvim_replace_termcodes("<Right>", true, true, true)
  end
end

-- Required to support nested placeholders
-- From https://github.com/L3MON4D3/LuaSnip/wiki/Nice-Configs#imitate-vscodes-behaviour-for-nested-placeholders
local util = require("luasnip.util.util")

require("luasnip").config.setup({
  store_selection_keys = "<Tab>",
  parser_nested_assembler = function(_, snippet)
    local select = function(snip, no_move)
      snip.parent:enter_node(snip.indx)
      -- upon deletion, extmarks of inner nodes should shift to end of
      -- placeholder-text.
      for _, node in ipairs(snip.nodes) do
        node:set_mark_rgrav(true, true)
      end

      -- SELECT all text inside the snippet.
      if not no_move then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
        local pos_begin, pos_end = snip.mark:pos_begin_end()
        util.normal_move_on(pos_begin)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("v", true, false, true), "n", true)
        util.normal_move_before(pos_end)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o<C-G>", true, false, true), "n", true)
      end
    end
    function snippet:jump_into(dir, no_move)
      if self.active then
        -- inside snippet, but not selected.
        if dir == 1 then
          self:input_leave()
          return self.next:jump_into(dir, no_move)
        else
          select(self, no_move)
          return self
        end
      else
        -- jumping in from outside snippet.
        self:input_enter()
        if dir == 1 then
          select(self, no_move)
          return self
        else
          return self.inner_last:jump_into(dir, no_move)
        end
      end
    end
    -- this is called only if the snippet is currently selected.
    function snippet:jump_from(dir, no_move)
      if dir == 1 then
        return self.inner_first:jump_into(dir, no_move)
      else
        self:input_leave()
        return self.prev:jump_into(dir, no_move)
      end
    end
    return snippet
  end,
})
