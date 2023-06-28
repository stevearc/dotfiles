return {
  "andymass/vim-matchup",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "[[", "<plug>(matchup-[%)", mode = { "n", "x" } },
    { "]]", "<plug>(matchup-]%)", mode = { "n", "x" } },
  },
  init = function()
    vim.g.matchup_surround_enabled = 1
    vim.g.matchup_matchparen_nomode = "i"
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_matchparen_deferred_show_delay = 400
    vim.g.matchup_matchparen_deferred_hide_delay = 400
    vim.g.matchup_matchparen_offscreen = {}
  end,
}
