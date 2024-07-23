return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "stevearc/vim-vscode-snippets",
  },
  event = "InsertEnter *",
  keys = {
    { "<Tab>", mode = "x" },
  },
  opts = {
    modules = {},
  },
  config = function(_, opts)
    local luasnip = require("luasnip")
    require("luasnip.loaders.from_vscode").lazy_load()
    vim.keymap.set({ "i", "s" }, "<C-k>", function() pcall(luasnip.change_choice, -1) end)
    vim.keymap.set({ "i", "s" }, "<C-j>", function() pcall(luasnip.change_choice, 1) end)

    local aug = vim.api.nvim_create_augroup("ClearLuasnipSession", { clear = true })
    -- Can't use InsertLeave here because that fires when we go to select mode
    vim.api.nvim_create_autocmd("CursorHold", {
      desc = "Deactivate snippet after leaving insert/select mode",
      pattern = "*",
      group = aug,
      callback = function()
        vim.cmd.LuaSnipUnlinkCurrent({ mods = { emsg_silent = true } })
        vim.snippet.stop()
      end,
    })

    vim.keymap.set({ "i", "s" }, "<C-h>", function()
      if luasnip.get_active_snip() then
        luasnip.jump(-1)
      elseif vim.snippet.active() then
        vim.snippet.jump(-1)
      else
        local cur = vim.api.nvim_win_get_cursor(0)
        pcall(vim.api.nvim_win_set_cursor, 0, { cur[1], cur[2] - 1 })
      end
    end)
    vim.keymap.set({ "i", "s" }, "<C-l>", function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif luasnip.get_active_snip() then
        luasnip.jump(1)
      elseif vim.snippet.active() then
        vim.snippet.jump(1)
      else
        local cur = vim.api.nvim_win_get_cursor(0)
        pcall(vim.api.nvim_win_set_cursor, 0, { cur[1], cur[2] + 1 })
      end
    end)

    vim.keymap.set({ "i", "s" }, "<Tab>", function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif luasnip.get_active_snip() then
        luasnip.jump(1)
      elseif vim.snippet.active() then
        vim.snippet.jump(1)
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", true)
      end
    end)

    -- Required to support nested placeholders
    -- From https://github.com/L3MON4D3/LuaSnip/wiki/Nice-Configs#imitate-vscodes-behaviour-for-nested-placeholders
    local util = require("luasnip.util.util")

    luasnip.config.setup({
      store_selection_keys = "<Tab>",
      updateevents = "TextChanged,TextChangedI",
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

    local function load_snippets(reload)
      for k in pairs(opts.modules) do
        local mod = "snippets." .. k
        if reload then
          package.loaded[mod] = nil
        end
        local ok, err = pcall(require, mod)
        if not ok then
          vim.notify(string.format("Error loading snippet module '%s': %s", k, err), vim.log.levels.ERROR)
        end
      end
    end
    local function reload()
      require("luasnip.loaders.from_vscode").load()
      load_snippets(true)
    end

    load_snippets(false)
    vim.api.nvim_create_user_command("LuaSnipReload", reload, { bar = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      desc = "Reload snippets on write",
      pattern = "*",
      group = aug,
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if
          bufname:match("/snippets/.+%.lua$")
          or bufname:match("/snippets/.+%.json$")
          or bufname:match("package.json$")
        then
          vim.notify("Reloading snippets", vim.log.levels.INFO)
          reload()
        end
      end,
    })
  end,
}
