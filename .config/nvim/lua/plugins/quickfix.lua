local function bufgrep(text)
  vim.cmd.cclose()
  vim.cmd("%argd")
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" and name ~= "" then
      vim.cmd.argadd({ args = { name } })
    end
  end
  vim.cmd.vimgrep({ args = { string.format("/%s/gj", text), "##" }, mods = { silent = true } })
  require("quicker").open({ open_cmd_mods = { split = "botright" } })
end

vim.keymap.set("n", "gw", "<cmd>cclose | Grep <cword><CR>", { desc = "Grep for word" })
vim.keymap.set("n", "gbw", function() bufgrep(vim.fn.expand("<cword>")) end, { desc = "Grep open buffers for word" })
vim.keymap.set("n", "gbW", function() bufgrep(vim.fn.expand("<cWORD>")) end, { desc = "Grep open buffers for WORD" })
vim.api.nvim_create_user_command("Bufgrep", function(params) bufgrep(params.args) end, { nargs = "+" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>", { desc = "Next quickfix item" })

return {
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      follow = {
        enabled = true,
      },
      highlight = {
        load_buffers = false,
      },
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
            vim.api.nvim_win_set_height(0, math.min(20, vim.api.nvim_buf_line_count(0)))
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
            vim.api.nvim_win_set_height(0, math.max(4, math.min(10, vim.api.nvim_buf_line_count(0))))
          end,
          desc = "Collapse quickfix context",
        },
        {
          "gdt",
          "<CMD>g/test.* /d<CR>:w<CR>",
          desc = "Delete lines with 'test' in the filename",
        },
      },
    },
    keys = {
      {
        "<leader>q",
        function() require("quicker").toggle({ open_cmd_mods = { split = "botright" } }) end,
        desc = "Toggle [Q]uickfix",
      },
      {
        "<leader>l",
        function() require("quicker").toggle({ loclist = true }) end,
        desc = "Toggle [L]oclist",
      },
      {
        "<leader>Q",
        function()
          vim.fn.setqflist({}, "a", {
            items = {
              {
                bufnr = vim.api.nvim_get_current_buf(),
                lnum = vim.api.nvim_win_get_cursor(0)[1],
                text = vim.api.nvim_get_current_line(),
              },
            },
          })
        end,
        desc = "Add to [Q]uickfix",
      },
    },
  },
}
