local null_ls = require("null-ls")
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local FORMATTING = methods.internal.FORMATTING
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

-- TODO
-- * pandoc rst seems to not be attaching to buffer

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
      if utils.root_has_file("yarn.lock") and vim.fn.executable("yarn") ~= 0 then
        return config.with({
          command = "yarn",
          args = prefix_args({ "--silent", command }),
        })
      elseif utils.root_has_file("package.json") and vim.fn.executable("npx") ~= 0 then
        return config.with({
          command = "npx",
          args = prefix_args({ command }),
        })
      elseif vim.fn.executable(command) ~= 0 then
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

null_ls.builtins.diagnostics.mypy = h.make_builtin({
  method = DIAGNOSTICS,
  filetypes = { "python" },
  generator_opts = {
    command = "mypy",
    args = {
      "--show-error-codes",
      "--show-column-numbers",
      "--no-color-output",
      "--follow-imports",
      "silent",
      "$FILENAME",
    },
    to_stdin = false,
    to_temp_file = true,
    from_stderr = true,
    format = "line",
    on_output = h.diagnostics.from_pattern(
      "(%w+):(%d+):(%d+): (%w+): (.+) %[(.+)%]",
      { "_file", "row", "col", "severity", "message", "code" },
      {
        severities = {
          error = h.diagnostics.severities["error"],
          warning = h.diagnostics.severities["warning"],
          note = h.diagnostics.severities["information"],
        },
      }
    ),
  },
  factory = h.generator_factory,
})

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

null_ls.builtins.formatting.pandoc_md = h.make_builtin({
  method = FORMATTING,
  filetypes = { "markdown" },
  generator_opts = {
    command = "pandoc",
    args = { "-f", "markdown", "-t", "gfm", "-sp", "--tab-stop=2", "-" },
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
      condition = function(utils)
        return utils.root_has_file("stylua.toml") or utils.root_has_file(".stylua.toml")
      end,
    }),
    null_ls.builtins.diagnostics.luacheck.with({
      args = { "--globals", "vim", "--formatter", "plain", "--codes", "--ranges", "--filename", "$FILENAME", "-" },
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),

    -- markdown
    null_ls.builtins.formatting.pandoc_md,

    -- php
    null_ls.builtins.formatting.hackfmt,

    -- python
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black,
    null_ls.builtins.diagnostics.pylint.with({
      condition = function()
        return vim.fn.executable("pylint") ~= 0
      end,
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),
    null_ls.builtins.diagnostics.mypy.with({
      condition = function()
        return vim.fn.executable("mypy") ~= 0
      end,
      diagnostics_format = "[#{c}] #{m} (#{s})",
    }),

    -- rst
    null_ls.builtins.formatting.pandoc_rst,
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
