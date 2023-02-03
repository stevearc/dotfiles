-- Treesitter parser requires a compiler with C++14 support
-- On mac, you can get this with `brew install gcc`
local enabled = true
if vim.loop.os_uname().sysname == "Darwin" then
  enabled = false
  local bins = vim.split(vim.fn.glob("/opt/homebrew/Cellar/gcc/*/bin/gcc-*"), "\n")
  for _, bin in ipairs(bins) do
    local basename = vim.fn.fnamemodify(bin, ":t")
    if basename:match("^gcc%-%d+$") then
      vim.env.CC = bin
      enabled = true
      break
    end
  end
end
return {
  "nvim-neorg/neorg",
  enabled = enabled,
  build = ":Neorg sync-parsers",
  event = "VeryLazy",
  opts = {
    load = {
      ["core.defaults"] = {}, -- Loads default behaviour
      ["core.norg.concealer"] = {}, -- Adds pretty icons to your documents
      ["core.norg.esupports.metagen"] = {
        config = {
          type = "auto",
        },
      },
      ["core.presenter"] = {
        config = {
          zen_mode = "zen-mode",
        },
      },
    },
  },
  dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
}
