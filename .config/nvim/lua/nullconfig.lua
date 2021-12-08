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

local function sandbox_js_command(config, command, args)
  local function prefix_args(prefix)
    return function(params)
      prefix = vim.list_extend({}, prefix)
      if type(args) == "table" then
        return vim.list_extend(prefix, args)
      else
        return vim.list_extend(prefix, args(params))
      end
    end
  end
  return config.with({
    condition = function(utils)
      if utils.root_has_file("yarn.lock") and is_exe("yarn") ~= 0 then
        return config.with({
          command = "yarn",
          args = prefix_args({ "--silent", command }),
        })
      elseif utils.root_has_file("package.json") and is_exe("npx") ~= 0 then
        return config.with({
          command = "npx",
          args = prefix_args({ command }),
        })
      elseif is_exe(command) ~= 0 then
        return config.with({
          command = command,
          args = args,
        })
      else
        return false
      end
    end,
  })
end

null_ls.builtins.diagnostics.yamllint = h.make_builtin({
  method = DIAGNOSTICS,
  filetypes = { "yaml" },
  generator_opts = {
    command = "yamllint",
    args = { "-f", "parsable", "-" },
    to_stdin = true,
    format = "line",
    on_output = h.diagnostics.from_pattern(
      [[(%w+):(%d+):(%d+): %[(%w+)%] (.+) %((.+)%)]],
      { "_file", "row", "col", "severity", "message", "code" }
    ),
  },
  factory = h.generator_factory,
})

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
    null_ls.builtins.formatting.clang_format,

    -- go
    null_ls.builtins.formatting.goimports,
    null_ls.builtins.formatting.gofmt,

    -- javascript and derivatives
    sandbox_js_command(
      null_ls.builtins.formatting.prettier,
      "prettier",
      h.range_formatting_args_factory({ "--stdin-filepath", "$FILENAME" })
    ),

    -- lua
    null_ls.builtins.formatting.stylua.with({
      runtime_condition = has_root_pattern("stylua.toml", ".stylua.toml"),
    }),
    null_ls.builtins.diagnostics.luacheck.with({
      args = { "--globals", "vim", "--formatter", "plain", "--codes", "--ranges", "--filename", "$FILENAME", "-" },
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),

    -- php
    null_ls.builtins.formatting.hackfmt,

    -- python
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black,
    null_ls.builtins.diagnostics.pylint.with({
      condition = function()
        return is_exe("pylint") ~= 0
      end,
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),
    null_ls.builtins.diagnostics.mypy.with({
      condition = function()
        return is_exe("mypy") ~= 0
      end,
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),

    -- rst
    null_ls.builtins.diagnostics.rstlint,

    -- sh
    null_ls.builtins.diagnostics.shellcheck.with({
      args = { "-x", "--format", "json1", "-" },
    }),
    null_ls.builtins.formatting.shfmt.with({
      args = { "-ci", "-i", "2", "-s", "-bn" },
    }),

    -- sql
    null_ls.builtins.formatting.sqlformat,

    -- supercollider
    null_ls.builtins.formatting.trim_whitespace.with({ filetypes = { "supercollider" } }),

    -- vim
    null_ls.builtins.diagnostics.vint.with({
      args = { "--enable-neovim", "--style-problem", "--json", "$FILENAME" },
    }),

    -- xml
    null_ls.builtins.formatting.xmllint,

    -- yaml
    null_ls.builtins.diagnostics.yamllint.with({
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),
  },
}
