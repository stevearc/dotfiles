local queries = require("nvim-treesitter.query")
local parsers = require("nvim-treesitter.parsers")

require("nvim-treesitter.configs").setup({
  ensure_installed = vim.g.treesitter_languages,
  ignore_install = vim.g.treesitter_languages_blacklist,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
    -- The python indent is driving me insane
    disable = { "lua", "python" },
  },
  matchup = {
    enable = true,
  },
  textsubjects = {
    enable = true,
    keymaps = {
      ["."] = "textsubjects-smart",
    },
  },
})

vim.cmd("autocmd WinEnter * lua stevearc.set_ts_win_defaults()")
vim.cmd("autocmd BufWinEnter * lua stevearc.set_ts_win_defaults()")

function stevearc.set_ts_win_defaults()
  local parser_name = parsers.get_buf_lang()
  if parsers.has_parser(parser_name) then
    local ok, has_folds = pcall(queries.get_query, parser_name, "folds")
    if ok and has_folds then
      if vim.wo.foldmethod == "manual" then
        vim.api.nvim_win_set_var(0, "ts_prev_foldmethod", vim.wo.foldmethod)
        vim.api.nvim_win_set_var(0, "ts_prev_foldexpr", vim.wo.foldexpr)
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
      end
      return
    end
  end
  if vim.wo.foldexpr == "nvim_treesitter#foldexpr()" then
    local ok, prev_foldmethod = pcall(vim.api.nvim_win_get_var, 0, "ts_prev_foldmethod")
    if ok and prev_foldmethod then
      vim.api.nvim_win_del_var(0, "ts_prev_foldmethod")
      vim.wo.foldmethod = prev_foldmethod
    end
    local ok2, prev_foldexpr = pcall(vim.api.nvim_win_get_var, 0, "ts_prev_foldexpr")
    if ok2 and prev_foldexpr then
      vim.api.nvim_win_del_var(0, "ts_prev_foldexpr")
      vim.wo.foldexpr = prev_foldexpr
    end
  end
end
