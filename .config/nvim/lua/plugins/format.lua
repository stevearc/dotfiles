local prettier = { "prettierd", "prettier", stop_after_first = true }
---@param bufnr integer
---@param ... string
---@return string
local function first(bufnr, ...)
  local conform = require("conform")
  for i = 1, select("#", ...) do
    local formatter = select(i, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "=",
      function()
        require("conform").format({ async = true }, function(err)
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            if vim.startswith(string.lower(mode), "v") then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            end
          end
        end)
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    default_format_opts = {
      lsp_format = "fallback",
    },
    formatters_by_ft = {
      javascript = prettier,
      typescript = prettier,
      javascriptreact = prettier,
      typescriptreact = prettier,
      css = prettier,
      graphql = prettier,
      html = prettier,
      json = prettier,
      json5 = prettier,
      jsonc = prettier,
      yaml = prettier,
      markdown = function(bufnr) return { first(bufnr, "prettierd", "prettier"), "injected" } end,
      norg = { "injected" },
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      query = { "format-queries" },
      sh = { "shfmt" },
      python = { "isort", "black" },
      zig = { "zigfmt" },
      ["_"] = { "trim_whitespace", "trim_newlines" },
    },
    formatters = {
      injected = {
        options = {
          lang_to_formatters = {
            html = {},
          },
        },
      },
      -- Dealing with old version of prettierd that doesn't support range formatting
      prettierd = {
        ---@diagnostic disable-next-line: assign-type-mismatch
        range_args = false,
      },
    },
    log_level = vim.log.levels.TRACE,
    format_after_save = function(bufnr)
      if vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 5000, lsp_format = "fallback" }
    end,
  },
  init = function() vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" end,
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
      opts.format_after_save = false
    end
    require("conform").setup(opts)
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
