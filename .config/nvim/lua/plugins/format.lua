vim.g.no_format_filetypes = vim.g.no_format_filetypes or {}
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
      zig = { "zigfmt" },
    },
    log_level = vim.log.levels.DEBUG,
  },
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
    end
    require("conform").setup(opts)
    local aug = vim.api.nvim_create_augroup("Conform", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      group = aug,
      callback = function(args)
        if vim.tbl_contains(vim.g.no_format_filetypes, vim.bo[args.buf].filetype) then
          return
        end
        if not vim.g.disable_autoformat and not vim.b[args.buf].disable_autoformat then
          require("conform").format({ timeout_ms = 500, lsp_fallback = true, buf = args.buf })
        end
      end,
    })
  end,
}
