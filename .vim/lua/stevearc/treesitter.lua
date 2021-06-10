local queries = require'nvim-treesitter.query'
local parsers = require'nvim-treesitter.parsers'
local M = {}

M.setup = function()
  require'treesitter-context.config'.setup{
    enable = true,
  }
  vim.cmd("autocmd WinEnter * lua require'stevearc.treesitter'.set_win_defaults()")
  vim.cmd("autocmd BufWinEnter * lua require'stevearc.treesitter'.set_win_defaults()")
end

M.set_win_defaults = function()
  local parser_name = parsers.get_buf_lang()
  if parsers.has_parser(parser_name) then
    local ok, has_folds = pcall(queries.get_query, parser_name, 'folds')
    if ok and has_folds then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
      return
    end
  end
  if vim.wo.foldexpr == 'nvim_treesitter#foldexpr()' then
    vim.wo.foldmethod = 'manual'
    vim.wo.foldexpr = '0'
  end
end

return M
