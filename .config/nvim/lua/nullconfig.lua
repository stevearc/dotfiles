local null_ls = require("null-ls")
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local util = require("lspconfig.util")
local FORMATTING = methods.internal.FORMATTING
local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local CONDITION = "_null_ls_root"

local find_vc_root = util.root_pattern(".git", ".hg")

-- Add some non-standard filetypes to prettier
vim.list_extend(
  null_ls.builtins.formatting.prettier.filetypes,
  { "jsonc", "json5", "javascript.jsx", "typescript.tsx" }
)

local function is_exe(name)
  return vim.fn.executable(name) ~= 0
end

local function cache_conditional(fn)
  return function(params)
    local ok, cached = pcall(vim.api.nvim_buf_get_var, params.bufnr, CONDITION)
    if ok then
      return cached
    end
    local ret = fn(params)
    -- Convert nil value to false
    vim.api.nvim_buf_set_var(params.bufnr, CONDITION, ret or false)
    return ret
  end
end

local function has_exe(name)
  return function()
    return is_exe(name)
  end
end

local function runtime_has_exe(name)
  return cache_conditional(function()
    return is_exe(name)
  end)
end

-- A runtime condition for enforcing the existence of files
local function has_root_pattern(...)
  local find = util.root_pattern(...)
  return cache_conditional(function(params)
    local vc_root = find_vc_root(params.bufname)
    local found = find(params.bufname)
    -- Don't search above the closest git root (might be a submodule)
    if found and vc_root and string.len(found) < string.len(vc_root) then
      return nil
    end
    return found
  end)
end

null_ls.builtins.diagnostics.rstlint = h.make_builtin({
  method = DIAGNOSTICS,
  filetypes = { "rst" },
  generator_opts = {
    command = "rst-lint",
    args = { "--level", "info", "--format", "json", "$FILENAME" },
    to_temp_file = true,
    from_stderr = true,
    format = "json",
    on_output = h.diagnostics.from_json({
      attributes = { line = "row", type = "severity", message = "message" },
      severities = {
        INFO = h.diagnostics.severities["information"],
        WARNING = h.diagnostics.severities["warning"],
        ERROR = h.diagnostics.severities["error"],
        SEVERE = h.diagnostics.severities["error"],
      },
    }),
  },
  factory = h.generator_factory,
})

null_ls.builtins.formatting.xmllint = h.make_builtin({
  method = FORMATTING,
  filetypes = { "xml" },
  generator_opts = {
    command = "xmllint",
    args = { "--format", "-" },
    to_stdin = true,
  },
  factory = h.formatter_factory,
})

null_ls.builtins.formatting.hackfmt = h.make_builtin({
  method = FORMATTING,
  filetypes = { "php" },
  generator_opts = {
    command = "hackfmt",
    args = {},
    to_stdin = true,
  },
  factory = h.formatter_factory,
})

null_ls.builtins.formatting.pandoc_rst = h.make_builtin({
  method = FORMATTING,
  filetypes = { "rst" },
  generator_opts = {
    command = "pandoc",
    args = { "-f", "rst", "-t", "rst", "-s", "--columns=79", "-" },
    to_stdin = true,
  },
  factory = h.formatter_factory,
})

return {
  debug = false,
  diagnostics_format = "#{m} (#{s})",

  sources = {
    -- C/C++
    null_ls.builtins.formatting.clang_format.with({
      condition = has_exe("clang-format"),
    }),

    -- go
    null_ls.builtins.formatting.goimports.with({
      condition = has_exe("goimports"),
    }),
    null_ls.builtins.formatting.gofmt.with({
      condition = has_exe("gofmt"),
    }),

    -- javascript and derivatives
    null_ls.builtins.formatting.prettier,

    -- lua
    null_ls.builtins.formatting.stylua.with({
      condition = has_exe("stylua"),
      runtime_condition = has_root_pattern("stylua.toml", ".stylua.toml"),
    }),

    -- php
    null_ls.builtins.formatting.hackfmt.with({
      condition = has_exe("hackfmt"),
    }),

    -- python
    null_ls.builtins.formatting.isort.with({
      runtime_condition = runtime_has_exe("isort"),
    }),
    null_ls.builtins.formatting.black.with({
      runtime_condition = runtime_has_exe("black"),
    }),

    -- sh
    null_ls.builtins.formatting.shfmt.with({
      condition = has_exe("shfmt"),
      args = { "-ci", "-i", "2", "-s", "-bn" },
    }),

    -- sql
    null_ls.builtins.formatting.sqlformat,

    -- supercollider
    null_ls.builtins.formatting.trim_whitespace.with({ filetypes = { "supercollider" } }),
  },

  -- Export this for use in other locations
  has_root_pattern = has_root_pattern,
  has_exe = has_exe,
  runtime_has_exe = runtime_has_exe,
}
