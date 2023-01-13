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
    require("overseer").setup(opts)
    vim.api.nvim_create_user_command("OverseerDebugParser", 'lua require("overseer").debug_parser()', {})
  end,
}
