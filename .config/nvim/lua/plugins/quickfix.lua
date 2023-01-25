local function bufgrep(text)
  vim.cmd.cclose()
  vim.cmd("%argd")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.cmd.bufdo({ args = { "argadd", "%" } })
  vim.api.nvim_set_current_buf(bufnr)
  vim.cmd.vimgrep({ args = { string.format("/%s/gj", text), "##" }, mods = { silent = true } })
  vim.cmd("QFOpen!")
end

vim.keymap.set("n", "gw", "<cmd>cclose | silent grep! <cword> | QFOpen!<CR>")
vim.keymap.set("n", "gbw", function()
  bufgrep(vim.fn.expand("<cword>"))
end)
vim.keymap.set("n", "gbW", function()
  bufgrep(vim.fn.expand("<cWORD>"))
end)
vim.api.nvim_create_user_command("Bufgrep", function(params)
  bufgrep(params.args)
end, { nargs = "+" })

return {
  {
    "stefandtw/quickfix-reflector.vim",
    event = "QuickFixCmdPost *",
  },
  {
    "stevearc/qf_helper.nvim",
    cmd = {
      "Cclear",
      "Lclear",
      "QNext",
      "QPrev",
      "QFNext",
      "QFPrev",
      "LLNext",
      "LLPrev",
      "QFOpen",
      "LLOpen",
      "QFToggle",
      "LLToggle",
    },
    keys = {
      { "<C-N>", "<cmd>QNext<CR>", mode = "n" },
      { "<C-P>", "<cmd>QPrev<CR>", mode = "n" },
      { "<leader>q", "<cmd>QFToggle!<CR>", mode = "n" },
      { "<leader>l", "<cmd>LLToggle!<CR>", mode = "n" },
    },
    config = function()
      vim.cmd([[
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])
]])
      require("qf_helper").setup()
    end,
  },
}
