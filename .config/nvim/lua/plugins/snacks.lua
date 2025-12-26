return {
  "folke/snacks.nvim",
  priority = 1000,
  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    bigfile = {},
    input = {},
    notifier = {
      top_down = false,
      margin = { top = 1, right = 1, bottom = 1 },
    },
    picker = {
      ui_select = true,
      main = {
        file = false,
      },
    },
  },
  keys = {
    {
      "<leader>ba",
      function()
        Snacks.picker.buffers({ layout = {
          preview = false,
        } })
      end,
      desc = "[B]uffers [A]ll",
    },
    {
      "<leader>bb",
      function()
        Snacks.picker.buffers({ layout = {
          preview = false,
        }, filter = { cwd = true } })
      end,
      desc = "[B]uffer [B]uffet",
    },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>fu", function() Snacks.picker.lines() end, desc = "[F]ind b[u]ffer line" },
    { "<leader>fb", function() Snacks.picker.grep_buffers() end, desc = "[F]ind in open [B]uffers" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "[F]ind by [G]rep" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "[F]ind in [H]elp" },
    { "<leader>fc", function() Snacks.picker.commands() end, desc = "[F]ind [C]ommand" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "[F]ind [K]eymap" },
    { "<leader>fw", function() Snacks.picker.lsp_workspace_symbols() end, desc = "[F]ind [W]orkspace symbol" },
  },
  lazy = false,
  config = function(_, opts)
    require("snacks").setup(opts)
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
    -- Load notifier immediately because at require-time it calls nvim_create_namespace, and that
    -- will error if it's called inside a lua loop callback. Which sometimes happens.
    require("snacks.notifier")
    vim.api.nvim_create_user_command("Notifications", function() Snacks.notifier.show_history() end, {})
  end,
}
