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
  vim.cmd("QFOpen!")
end

vim.keymap.set("n", "gw", "<cmd>cclose | Grep <cword><CR>", { desc = "Grep for word" })
vim.keymap.set("n", "gbw", function() bufgrep(vim.fn.expand("<cword>")) end, { desc = "grep open buffers for word" })
vim.keymap.set("n", "gbW", function() bufgrep(vim.fn.expand("<cWORD>")) end, { desc = "Grep open buffers for WORD" })
vim.api.nvim_create_user_command("Bufgrep", function(params) bufgrep(params.args) end, { nargs = "+" })

return {
  {
    "stefandtw/quickfix-reflector.vim",
    ft = "qf",
  },
  {
    "stevearc/qf_helper.nvim",
    ft = "qf",
    cmd = { "QNext", "QPrev", "QFToggle", "QFOpen", "LLToggle" },
    keys = {
      { "<C-N>", "<cmd>QNext<CR>", desc = "[N]ext in quickfix" },
      { "<C-P>", "<cmd>QPrev<CR>", desc = "[P]rev in quickfix" },
      { "<leader>q", "<cmd>QFToggle!<CR>", desc = "Toggle [Q]uickfix" },
      { "<leader>l", "<cmd>LLToggle!<CR>", desc = "Toggle [L]oclist" },
    },
    opts = {
      prefer_loclist = false,
      default_bindings = false,
    },
  },
}
