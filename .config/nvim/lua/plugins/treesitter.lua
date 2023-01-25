return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
    },
    config = function()
      local queries = require("nvim-treesitter.query")
      local parsers = require("nvim-treesitter.parsers")

      local disable_max_size = 2000000 -- 2MB

      local function should_disable(lang, bufnr)
        local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
        -- size will be -2 if it doesn't fit into a number
        if size > disable_max_size or size == -2 then
          return true
        end
        return false
      end

      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "markdown", "markdown_inline", "help", "bash" },
        ignore_install = { "supercollider", "phpdoc" },
        auto_install = true,
        highlight = {
          enable = true,
          disable = should_disable,
        },
        indent = {
          enable = true,
          disable = function(lang, bufnr)
            if lang == "lua" then -- or lang == "python" then
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
        textobjects = {
          select = {
            enable = true,
            disable = should_disable,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
            },
            include_surrounding_whitespace = false,
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
              ["]b"] = "@block.outer",
              ["]l"] = "@loop.outer",
              ["]i"] = "@conditional.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.inner",
              ["]B"] = "@block.outer",
              ["]L"] = "@loop.outer",
              ["]I"] = "@conditional.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
              ["[b"] = "@block.outer",
              ["[l"] = "@loop.outer",
              ["[i"] = "@conditional.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.inner",
              ["[B"] = "@block.outer",
              ["[L"] = "@loop.outer",
              ["[I"] = "@conditional.outer",
            },
          },
        },
      })

      local function set_ts_win_defaults()
        local parser_name = parsers.get_buf_lang()
        if parsers.has_parser(parser_name) and not should_disable(parser_name, 0) then
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

      local aug = vim.api.nvim_create_augroup("StevearcTSConfig", {})
      vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        desc = "Set treesitter defaults on win enter",
        pattern = "*",
        callback = set_ts_win_defaults,
        group = aug,
      })
    end,
  },
  {
    "nvim-treesitter/playground",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
  },
}
