local is_windows = vim.loop.os_uname().version:match("Windows")
local sep = is_windows and "\\" or "/"
return {
  "stevearc/three.nvim",
  opts = {
    projects = {
      allowlist = {
        vim.fn.stdpath("data") .. "/lazy",
      },
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
    local three = require("three")
    three.setup(opts)
    vim.keymap.set("n", "L", three.next, { desc = "Next buffer" })
    vim.keymap.set("n", "H", three.prev, { desc = "Previous buffer" })
    vim.keymap.set("n", "<C-l>", three.move_right, { desc = "Move buffer right" })
    vim.keymap.set("n", "<C-h>", three.move_left, { desc = "Move buffer left" })
    vim.keymap.set("n", "<C-j>", three.wrap(three.next_tab, { wrap = true }, { desc = "[G]oto next [T]ab" }))
    vim.keymap.set("n", "<C-k>", three.wrap(three.prev_tab, { wrap = true }, { desc = "[G]oto prev [T]ab" }))
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
    vim.keymap.set("n", "<C-w><C-n>", "<cmd>tabnew | set nobuflisted<CR>", { desc = "New tab" })
    vim.keymap.set("n", "<C-w>`", three.toggle_scope_by_dir, { desc = "Toggle tab scoping by directory" })
    vim.api.nvim_create_user_command("BufCloseAll", function()
      three.close_all_buffers()
    end, {})
    vim.api.nvim_create_user_command("BufCloseAllButCurrent", function()
      three.close_all_buffers(function(info)
        return info.bufnr ~= vim.api.nvim_get_current_buf()
      end)
    end, {})
    vim.api.nvim_create_user_command("BufCloseAllButPinned", function()
      three.close_all_buffers(function(info)
        return not info.pinned
      end)
    end, {})
    vim.api.nvim_create_user_command("BufHideAll", function()
      three.hide_all_buffers()
    end, {})
    vim.api.nvim_create_user_command("BufHideAllButCurrent", function()
      three.hide_all_buffers(function(info)
        return info.bufnr ~= vim.api.nvim_get_current_buf()
      end)
    end, {})
    vim.api.nvim_create_user_command("BufHideAllButPinned", function()
      three.hide_all_buffers(function(info)
        return not info.pinned
      end)
    end, {})

    vim.keymap.set("n", "<C-w>+", function()
      local enabled = three.toggle_win_resize()
      vim.notify("Window resizing " .. (enabled and "ENABLED" or "DISABLED"))
    end, {})
    vim.keymap.set("n", "<C-w>z", "<cmd>resize | vertical resize<CR>", {})

    vim.keymap.set("n", "<leader>fp", three.open_project, { desc = "[F]ind [P]roject" })
    vim.api.nvim_create_user_command("ProjectDelete", function()
      three.remove_project()
    end, {})
  end,
}
