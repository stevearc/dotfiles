return {
  "stevearc/dressing.nvim",
  event = "VeryLazy",
  opts = {
    input = {
      insert_only = false,
      -- relative = "editor",
      win_options = {
        sidescrolloff = 4,
      },
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
