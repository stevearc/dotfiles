return {
  "andymass/vim-matchup",
  event = "VeryLazy",
  config = function()
    vim.keymap.set({ "n", "x" }, "[[", "<plug>(matchup-[%)")
    vim.keymap.set({ "n", "x" }, "]]", "<plug>(matchup-]%)")
  end,
  init = function()
    vim.g.matchup_surround_enabled = 1
    vim.g.matchup_matchparen_nomode = "i"
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_matchparen_deferred_show_delay = 400
    vim.g.matchup_matchparen_deferred_hide_delay = 400
    vim.g.matchup_matchparen_offscreen = {}
  end,
}
