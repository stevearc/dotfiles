local neogit = require("neogit")

local opts = {}
if vim.g.nerd_font then
  opts.signs = {
    section = { "", "" },
    item = { "", "" },
    hunk = { "", "" },
  }
end

neogit.setup(opts)

vim.api.nvim_set_keymap("n", "<leader>n", "<cmd>Neogit<CR>", { silent = true })
