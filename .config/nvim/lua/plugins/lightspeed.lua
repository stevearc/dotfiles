return {
  "ggandor/lightspeed.nvim",
  keys = {
    { "<leader>s", "<Plug>Lightspeed_omni_s", desc = "Lightspeed search" },
    { "gs", "<Plug>Lightspeed_omni_s", desc = "Lightspeed search" },
  },
  opts = {
    jump_to_unique_chars = false,
    safe_labels = {},
  },
  config = function(_, opts)
    require("lightspeed").setup(opts)
  end,
  init = function()
    vim.g.lightspeed_no_default_keymaps = true
  end,
}
