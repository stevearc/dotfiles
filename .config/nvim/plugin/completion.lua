local cmp = require("cmp")
local lspkind = require("lspkind")
local luasnip = require("luasnip")

vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")

local MAX_INDEX_FILE_SIZE = 4000

lspkind.init()

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local mapping = {
  ["<C-d>"] = cmp.mapping.scroll_docs(-4),
  ["<C-f>"] = cmp.mapping.scroll_docs(4),
  ["<C-e>"] = cmp.mapping.close(),
  ["<C-y>"] = cmp.mapping.confirm({
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  }),

  ["<C-space>"] = cmp.mapping.complete(),
}

if vim.g.snippet_engine == "luasnip" then
  require("luasnip.loaders.from_vscode").lazy_load()
  -- TODO need to have some keybinding to cycle through choice nodes
  vim.cmd([[
  aug ClearLuasnipSession
    au!
    " Can't use InsertLeave here because that fires when we go to select mode
    au CursorHold * silent lua require('luasnip').unlink_current()
  aug END
  ]])

  mapping["<Tab>"] = cmp.mapping(function(fallback)
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
  })

  mapping["<S-Tab>"] = cmp.mapping(function(fallback)
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
  })
end

cmp.setup({
  mapping = mapping,

  sources = {
    { name = "neorg" },
    { name = "nvim_lua" },
    { name = "nvim_lsp" },
    { name = "path" },
    { name = vim.g.snippet_engine },
    {
      name = "buffer",
      keyword_length = 4,
      opts = {
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
      if vim.g.snippet_engine == "luasnip" then
        require("luasnip").lsp_expand(args.body)
      else
        vim.fn["vsnip#anonymous"](args.body)
      end
    end,
  },

  formatting = {
    format = lspkind.cmp_format({
      with_text = true,
      menu = {
        buffer = "[buf]",
        nvim_lsp = "[LSP]",
        nvim_lua = "[api]",
        path = "[path]",
        luasnip = "[snip]",
      },
    }),
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
