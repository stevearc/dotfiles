safe_require("cmp", function(cmp)
  local luasnip = require("luasnip")

  local MAX_INDEX_FILE_SIZE = 4000

  local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
  end

  local mapping = cmp.mapping.preset.insert({
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.close(),
    ["<C-y>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),

    ["<C-space>"] = cmp.mapping.complete(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif cmp.visible() then
        cmp.select_next_item()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      elseif cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
  })

  local formatting = {}
  safe_require("lspkind", function(lspkind)
    formatting.format = lspkind.cmp_format({
      mode = "symbol",
      symbol_map = {
        Class = " ",
        Color = " ",
        Constant = " ",
        Constructor = " ",
        Enum = " ",
        EnumMember = " ",
        Event = "",
        Field = " ",
        File = " ",
        Folder = " ",
        Function = " ",
        Interface = " ",
        Keyword = " ",
        Method = " ",
        Module = " ",
        Operator = " ",
        Property = " ",
        Reference = " ",
        Snippet = " ",
        Struct = " ",
        Text = " ",
        Unit = "塞",
        Value = " ",
        Variable = " ",
      },
      menu = {
        buffer = "[buf]",
        nvim_lsp = "[LSP]",
        nvim_lua = "[api]",
        path = "[path]",
        luasnip = "[snip]",
      },
    })
  end)

  cmp.setup({
    mapping = mapping,
    formatting = formatting,

    sources = {
      { name = "overseer" },
      { name = "crates" },
      { name = "nvim_lua" },
      { name = "nvim_lsp" },
      { name = "path" },
      { name = "luasnip" },
      {
        name = "buffer",
        keyword_length = 4,
        options = {
          get_bufnrs = function()
            local bufs = {}
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              -- Don't index giant files
              if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_line_count(bufnr) < MAX_INDEX_FILE_SIZE then
                table.insert(bufs, bufnr)
              end
            end
            return bufs
          end,
        },
      },
    },

    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },

    experimental = {
      native_menu = false,
    },
  })

  -- Add vim-dadbod-completion in sql files
  vim.cmd([[
  augroup DadbodSql
    au!
    autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer { sources = { { name = 'vim-dadbod-completion' } } }
  augroup END
]])
end)
