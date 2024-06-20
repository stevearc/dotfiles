return {
  "stevearc/dressing.nvim",
  opts = {
    input = {
      -- relative = "editor",
      win_options = {
        sidescrolloff = 4,
      },
      get_config = function()
        if vim.api.nvim_win_get_width(0) < 50 then
          return {
            relative = "editor",
          }
        end
      end,
    },
    select = {
      backend = { "fzf_lua", "telescope", "builtin" },
    },
  },
  config = function(_, opts)
    require("dressing").setup(opts)
    vim.keymap.set("n", "z=", function()
      local word = vim.fn.expand("<cword>")
      local suggestions = vim.fn.spellsuggest(word)
      vim.ui.select(
        suggestions,
        {},
        vim.schedule_wrap(function(selected)
          if selected then
            vim.cmd.normal({ args = { "ciw" .. selected }, bang = true })
          end
        end)
      )
    end)
  end,
}
