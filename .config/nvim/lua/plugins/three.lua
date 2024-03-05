local uv = vim.uv or vim.loop
local is_windows = uv.os_uname().version:match("Windows")
local sep = is_windows and "\\" or "/"
return {
  {
    "stevearc/resession.nvim",
    lazy = true,
    opts = {
      extensions = {
        three = {},
      },
    },
  },
  {
    "stevearc/three.nvim",
    event = "VeryLazy",
    opts = {
      bufferline = {
        icon = {
          pin = "",
          pin_divider = "║",
        },
        events = { "BufWritePost", "BufWinLeave" },
        should_display = function(tabpage, bufnr, ts) return vim.bo[bufnr].modified end,
      },
      projects = {
        allowlist = {
          vim.fn.stdpath("data") .. "/lazy",
          vim.fs.normalize("~/dotfiles/vimplugins/openai.nvim"),
        },
        extra_allowlist = {},
        filter_dir = function(dir)
          local dotgit = dir .. sep .. ".git"
          if vim.fn.isdirectory(dotgit) == 1 or vim.fn.filereadable(dotgit) == 1 then
            return true
          end
          -- If this is the child directory of a .git directory, ignore
          return vim.fn.finddir(".git", dir .. ";") == ""
        end,
      },
    },
    config = function(_, opts)
      vim.list_extend(opts.projects.allowlist, vim.tbl_keys(opts.projects.extra_allowlist))
      local three = require("three")
      three.setup(opts)
      vim.keymap.set("n", "L", three.next, { desc = "Next buffer" })
      vim.keymap.set("n", "H", three.prev, { desc = "Previous buffer" })
      vim.keymap.set("n", "<C-l>", three.move_right, { desc = "Move buffer right" })
      vim.keymap.set("n", "<C-h>", three.move_left, { desc = "Move buffer left" })
      vim.keymap.set({ "n", "t" }, "<C-j>", three.wrap(three.next_tab, { wrap = true }, { desc = "[G]oto next [T]ab" }))
      vim.keymap.set({ "n", "t" }, "<C-k>", three.wrap(three.prev_tab, { wrap = true }, { desc = "[G]oto prev [T]ab" }))
      for i = 1, 9 do
        vim.keymap.set("n", "<leader>" .. i, three.wrap(three.jump_to, i))
      end
      vim.keymap.set("n", "<leader>`", three.wrap(three.next, { delta = 100 }))
      vim.keymap.set("n", "<leader>0", three.wrap(three.jump_to, 10))
      vim.keymap.set("n", "<leader>c", three.smart_close, { desc = "Smart [c]lose" })
      vim.keymap.set("n", "<leader>C", three.close_buffer, { desc = "[C]lose buffer" })
      vim.keymap.set("n", "<leader>bh", three.hide_buffer, { desc = "[B]uffer [H]ide" })
      vim.keymap.set("n", "<leader>bp", three.toggle_pin, { desc = "[B]uffer [P]in" })
      vim.keymap.set("n", "<leader>bi", three.toggle_pin, { desc = "[B]uffer P[i]n" })
      vim.keymap.set("n", "<leader>bm", function()
        vim.ui.input({ prompt = "Move buffer to:" }, function(idx)
          idx = idx and tonumber(idx)
          if idx then
            three.move_buffer(idx)
          end
        end)
      end, { desc = "[B]uffer [M]ove" })
      vim.keymap.set("n", "<C-w><C-t>", "<cmd>tabclose<CR>", { desc = "Close tab" })
      vim.keymap.set("n", "<C-w><C-b>", three.clone_tab, { desc = "Clone tab" })
      vim.keymap.set(
        "n",
        "<C-w><C-n>",
        "<cmd>tabnew | set nobuflisted | setlocal bufhidden=wipe<CR>",
        { desc = "New tab" }
      )
      vim.api.nvim_create_user_command("BufClean", function(args)
        local visible_buffers = {}
        for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
          local ts = three.get_tab_state(tabpage)
          for _, bufnr in ipairs(ts.buffers) do
            visible_buffers[bufnr] = true
          end
        end
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if (vim.bo[bufnr].buflisted or args.bang) and not visible_buffers[bufnr] then
            three.close_buffer(bufnr)
          end
        end
      end, { desc = "Delete all buffers that are not visible or in the bufferline", bang = true })
      vim.api.nvim_create_user_command("BufHideAll", function() three.hide_all_buffers() end, {})
      vim.api.nvim_create_user_command("BufHideAllButCurrent", function()
        three.hide_all_buffers(function(info) return info.bufnr ~= vim.api.nvim_get_current_buf() end)
      end, {})

      vim.keymap.set("n", "<C-w>+", function()
        local enabled = three.toggle_win_resize()
        vim.notify("Window resizing " .. (enabled and "ENABLED" or "DISABLED"))
      end, {})
      vim.keymap.set("n", "<C-w>z", "<cmd>resize | vertical resize<CR>", {})

      vim.keymap.set("n", "<leader>fp", three.open_project, { desc = "[F]ind [P]roject" })
      vim.api.nvim_create_user_command("ProjectDelete", function() three.remove_project() end, {})
    end,
  },
}
