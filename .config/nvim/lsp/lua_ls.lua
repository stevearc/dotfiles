-- HACK this is to handle an issue with lazydev + new version of lua_ls
-- https://github.com/folke/lazydev.nvim/issues/136
return {
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "snacks.nvim", words = { "Snacks" } },
        },
      },
    },
  },
}
