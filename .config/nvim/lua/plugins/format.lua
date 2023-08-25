local prettier = { "prettierd", "prettier" }
return {
  "stevearc/conform.nvim",
  event = { "FileType" },
  keys = {
    {
      "=",
      function()
        require("conform").format({ async = true })
      end,
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = prettier,
      typescript = prettier,
      javascriptreact = prettier,
      typescriptreact = prettier,
      css = prettier,
      html = prettier,
      json = prettier,
      jsonc = prettier,
      yaml = prettier,
      markdown = prettier,
      graphql = prettier,
      lua = { "stylua" },
      go = { "gofmt" },
      sh = { "shfmt" },
      python = {
        formatters = { "isort", "black" },
        run_all_formatters = true,
      },
    },
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
    log_level = vim.log.levels.DEBUG,
  },
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
    end
    require("conform").setup(opts)
  end,
}
