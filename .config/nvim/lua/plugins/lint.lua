local uv = vim.uv or vim.loop
return {
  "mfussenegger/nvim-lint",
  ft = { "lua", "python", "rst", "sh", "vim", "yaml", "javascript", "typescript" },
  opts = {
    linters_by_ft = {
      lua = { "luacheck" },
      python = { "mypy", "pylint" },
      rst = { "rstlint" },
      sh = { "shellcheck" },
      vim = { "vint" },
      yaml = { "yamllint" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      ["javascript.jsx"] = { "eslint_d" },
      ["typescript.tsx"] = { "eslint_d" },
    },
    linters = {},
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft
    for k, v in pairs(opts.linters) do
      lint.linters[k] = v
    end
    local timer = assert(uv.new_timer())
    local DEBOUNCE_MS = 500
    vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave" }, {
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        timer:stop()
        timer:start(
          DEBOUNCE_MS,
          0,
          vim.schedule_wrap(function()
            vim.api.nvim_buf_call(bufnr, lint.try_lint)
          end)
        )
      end,
    })
    lint.try_lint()
  end,
}
