safe_require("nvim-treesitter", function()
  local queries = require("nvim-treesitter.query")
  local parsers = require("nvim-treesitter.parsers")

  local disable_max_size = 1000000

  local function should_disable(lang, bufnr)
    local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
    -- size will be -2 if it doesn't fit into a number
    if size > disable_max_size or size == -2 then
      return true
    end
    return false
  end

  require("nvim-treesitter.configs").setup({
    ensure_installed = vim.g.treesitter_languages,
    ignore_install = vim.g.treesitter_languages_blacklist,
    highlight = {
      enable = true,
      disable = should_disable,
    },
    indent = {
      enable = true,
      disable = function(lang, bufnr)
        -- The python indent is driving me insane
        if lang == 'lua' or lang == 'python' then
          return true
        else
          return should_disable(lang, bufnr)
        end
      end,
    },
    matchup = {
      enable = true,
      disable = should_disable,
    },
    textsubjects = {
      enable = true,
      disable = should_disable,
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
end)
