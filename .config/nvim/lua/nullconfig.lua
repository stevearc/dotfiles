local null_ls = require("null-ls")
-- TODO
-- * Needs root pattern marker so we can run in correct directory
-- * If command is not available, is null-ls properly disabled for that filetype?
-- * luacheck
-- * mypy
-- * pylint
-- * yamllint
-- * pandoc rst
-- * pandoc md
-- * vint
-- * hackfmt
-- * xmllint

return {
  sources = {
    -- lua
    null_ls.builtins.formatting.stylua,

    -- python
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black,

    -- javascript and derivatives
    null_ls.builtins.formatting.prettier,

    -- sh
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.formatting.shfmt,

    -- supercollider
    null_ls.builtins.formatting.trim_whitespace.with({ filetypes = { "supercollider" } }),
  },
}
