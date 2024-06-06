return {
  "Zeioth/compiler.nvim",
  enabled = false,
  keys = {
    { "<leader>ob", "<CMD>CompilerOpen<CR>", desc = "[O]verseer [B]uild" },
  },
  cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
  dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
  opts = {},
}
