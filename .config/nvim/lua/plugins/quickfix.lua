local function bufgrep(text)
  vim.cmd.cclose()
  vim.cmd("%argd")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.cmd.bufdo({ args = { "argadd", "%" } })
  vim.api.nvim_set_current_buf(bufnr)
  vim.cmd.vimgrep({ args = { string.format("/%s/gj", text), "##" }, mods = { silent = true } })
  vim.cmd("QFOpen!")
end

vim.keymap.set("n", "gw", "<cmd>cclose | Grep <cword><CR>", { desc = "Grep for word" })
vim.keymap.set("n", "gbw", function()
  bufgrep(vim.fn.expand("<cword>"))
end, { desc = "grep open buffers for word" })
vim.keymap.set("n", "gbW", function()
  bufgrep(vim.fn.expand("<cWORD>"))
end, { desc = "Grep open buffers for WORD" })
vim.api.nvim_create_user_command("Bufgrep", function(params)
  bufgrep(params.args)
end, { nargs = "+" })

return {
  {
    "stefandtw/quickfix-reflector.vim",
    ft = "qf",
  },
  {
    "stevearc/qf_helper.nvim",
    ft = "qf",
    keys = {
      { "<C-N>", "<cmd>QNext<CR>", mode = "n" },
      { "<C-P>", "<cmd>QPrev<CR>", mode = "n" },
      { "<leader>q", "<cmd>QFToggle!<CR>", mode = "n" },
      { "<leader>l", "<cmd>LLToggle!<CR>", mode = "n" },
    },
    config = function()
      require("qf_helper").setup({
        prefer_loclist = false,
      })
    end,
  },
}
