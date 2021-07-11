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

vim.cmd([[
aug NeoGitMaps
  au! * <buffer>
  au FileType NeogitStatus nmap <buffer> <leader>c q
aug END
]])

vim.api.nvim_set_keymap("n", "<leader>gs", "<cmd>Neogit<CR>", { silent = true })
