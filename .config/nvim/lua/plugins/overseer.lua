return {
  "stevearc/overseer.nvim",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  cmd = { "OverseerDebugParser", "OverseerRun", "OverseerRunCmd", "OverseerInfo", "OverseerToggle", "OverseerOpen" },
  keys = {
    { "<leader>oo", "<cmd>OverseerToggle<CR>", mode = "n" },
    { "<leader>or", "<cmd>OverseerRun<CR>", mode = "n" },
    { "<leader>oc", "<cmd>OverseerRunCmd<CR>", mode = "n" },
    { "<leader>ol", "<cmd>OverseerLoadBundle<CR>", mode = "n" },
    { "<leader>ob", "<cmd>OverseerBuild<CR>", mode = "n" },
    { "<leader>od", "<cmd>OverseerQuickAction<CR>", mode = "n" },
    { "<leader>os", "<cmd>OverseerTaskAction<CR>", mode = "n" },
  },
  opts = {
    strategy = { "jobstart" },
    log = {
      {
        type = "echo",
        level = vim.log.levels.WARN,
      },
      {
        type = "file",
        filename = "overseer.log",
        level = vim.log.levels.DEBUG,
      },
    },
    task_launcher = {
      bindings = {
        n = {
          ["<leader>c"] = "Cancel",
        },
      },
    },
    component_aliases = {
      default = {
        { "display_duration", detail_level = 2 },
        "on_output_summarize",
        "on_exit_set_status",
        { "on_complete_notify", system = "unfocused" },
        "on_complete_dispose",
      },
      default_neotest = {
        { "on_complete_notify", system = "unfocused", on_change = true },
        "default",
      },
    },
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)
    vim.api.nvim_create_user_command("OverseerDebugParser", 'lua require("overseer").debug_parser()', {})
    vim.api.nvim_create_user_command("Grep", function(args)
      -- Interpolate the "$*" in grepprg
      local cmd, num_subs = vim.o.grepprg:gsub("%$%*", args.args)
      if num_subs == 0 then
        cmd = cmd .. " " .. args.args
      end
      local task = overseer.new_task({
        cmd = cmd,
        name = "grep " .. args.args,
        components = {
          {
            "on_output_quickfix",
            errorformat = vim.o.grepformat,
            open = true,
            open_height = 8,
            items_only = true,
          },
          { "on_complete_dispose", timeout = 30 },
          "default",
        },
      })
      task:start()
    end, { nargs = "*" })
  end,
}
