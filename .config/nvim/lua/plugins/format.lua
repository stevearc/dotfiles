local prettier = { "prettierd", "prettier" }
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = "ConformInfo",
  keys = {
    {
      "=",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { prettier },
      typescript = { prettier },
      javascriptreact = { prettier },
      typescriptreact = { prettier },
      css = { prettier },
      html = { prettier },
      json = { prettier },
      jsonc = { prettier },
      yaml = { prettier },
      markdown = { prettier },
      graphql = { prettier },
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      sh = { "shfmt" },
      python = { "isort", "black" },
      zig = { "zigfmt" },
    },
    log_level = vim.log.levels.DEBUG,
    format_on_save = function(bufnr)
      local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
      if async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
    format_after_save = function(bufnr)
      local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
      if not async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { lsp_fallback = true }
    end,
    user_async_format_filetypes = {
      python = true,
    },
  },
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
      opts.format_after_save = false
    end
    vim.g.async_format_filetypes = opts.user_async_format_filetypes
    require("conform").setup(opts)
  end,
}
