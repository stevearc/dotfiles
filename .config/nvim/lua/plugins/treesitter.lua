return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        bash = true,
        comment = true,
        git_rebase = true,
        gitcommit = true,
        lua = true,
        luadoc = true,
        markdown = true,
        markdown_inline = true,
        vim = true,
        vimdoc = true,
      },
    },
    config = function(_, opts)
      if vim.fn.executable("tree-sitter") == 0 then
        vim.notify("[nvim-treesitter] Missing tree-sitter-cli", vim.log.levels.WARN)
        return
      end
      local langs = {}
      for k, v in pairs(opts.ensure_installed) do
        if v then
          table.insert(langs, k)
        end
      end
      require("nvim-treesitter").install(langs)
      local disable_max_size = 2000000 -- 2MB

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Automatically install treesitter parser",
        pattern = "*",
        group = vim.api.nvim_create_augroup("treesitter_user_config", {}),
        callback = function(args)
          if vim.bo[args.buf].buftype == "" then
            local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(args.buf))
            -- size will be -2 if it doesn't fit into a number
            if size > disable_max_size or size == -2 then
              return true
            end
          end

          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if require("nvim-treesitter.parsers")[lang] ~= nil then
            require("nvim-treesitter").install(lang):await(function()
              local ts_supported = pcall(vim.treesitter.start, args.buf)
              if ts_supported then
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end)
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    init = function() vim.g.no_plugin_maps = true end,
    opts = {
      select = {
        lookahead = true,
      },
      move = {
        set_jumps = true,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)
      local keymaps = {
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
      }
      for k, v in pairs(keymaps) do
        vim.keymap.set(
          { "x", "o" },
          k,
          function() require("nvim-treesitter-textobjects.select").select_textobject(v, "textobjects") end
        )
      end
      local move_maps = {
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
      }
      for method, maps in pairs(move_maps) do
        for key, object in pairs(maps) do
          vim.keymap.set(
            { "n", "x", "o" },
            key,
            function() require("nvim-treesitter-textobjects.move")[method](object, "textobjects") end
          )
        end
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      multiline_threshold = 3,
      on_attach = function(bufnr)
        -- context is super wrong for zig
        return vim.bo[bufnr].filetype ~= "zig"
      end,
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)
      local aug = vim.api.nvim_create_augroup("StevearcTSConfig", {})
      vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "nvim-treesitter-context highlights",
        pattern = "*",
        command = "highlight link TreesitterContextLineNumber NormalFloat",
        group = aug,
      })
    end,
  },
}
