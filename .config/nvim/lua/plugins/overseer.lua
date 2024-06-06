return {
  {
    "stevearc/resession.nvim",
    lazy = true,
    opts = {
      extensions = {
        overseer = {
          status = { "RUNNING" },
        },
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = {
      "Grep",
      "Make",
      "OverseerDebugParser",
      "OverseerInfo",
      "OverseerOpen",
      "OverseerRun",
      "OverseerRunCmd",
      "OverseerToggle",
    },
    keys = {
      { "<leader>oo", "<cmd>OverseerToggle!<CR>", mode = "n", desc = "[O]verseer [O]pen" },
      { "<leader>or", "<cmd>OverseerRun<CR>", mode = "n", desc = "[O]verseer [R]un" },
      { "<leader>oc", "<cmd>OverseerRunCmd<CR>", mode = "n", desc = "[O]verseer run [C]ommand" },
      { "<leader>ol", "<cmd>OverseerLoadBundle<CR>", mode = "n", desc = "[O]verseer [L]oad" },
      { "<leader>od", "<cmd>OverseerQuickAction<CR>", mode = "n", desc = "[O]verseer [D]o quick action" },
      { "<leader>os", "<cmd>OverseerTaskAction<CR>", mode = "n", desc = "[O]verseer [S]elect task action" },
    },
    opts = {
      templates = { builtin = true },
      strategy = { "jobstart" },
      dap = false,
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
      task_list = {
        bindings = {
          dd = "Dispose",
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
          { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
        },
        default_neotest = {
          "unique",
          { "on_complete_notify", system = "unfocused", on_change = true },
          "default",
        },
      },
      post_setup = {},
    },
    config = function(_, opts)
      opts.templates = vim.tbl_keys(opts.templates)
      local overseer = require("overseer")
      overseer.setup(opts)
      for _, cb in pairs(opts.post_setup) do
        cb()
      end
      vim.api.nvim_create_user_command("OverseerDebugParser", 'lua require("overseer").debug_parser()', {})
      vim.api.nvim_create_user_command("OverseerTestOutput", function(params)
        vim.cmd.tabnew()
        vim.bo.bufhidden = "wipe"
        local TaskView = require("overseer.task_view")
        TaskView.new(0, {
          select = function(self, tasks)
            for _, task in ipairs(tasks) do
              if task.metadata.neotest_group_id then
                return task
              end
            end
            self:dispose()
          end,
        })
      end, {})
      vim.api.nvim_create_user_command("Grep", function(params)
        local args = vim.fn.expandcmd(params.args)
        -- Insert args at the '$*' in the grepprg
        local cmd, num_subs = vim.o.grepprg:gsub("%$%*", args)
        if num_subs == 0 then
          cmd = cmd .. " " .. args
        end
        local cwd
        local has_oil, oil = pcall(require, "oil")
        if has_oil then
          cwd = oil.get_current_dir()
        end
        local task = overseer.new_task({
          cmd = cmd,
          cwd = cwd,
          name = "grep " .. args,
          components = {
            {
              "on_output_quickfix",
              errorformat = vim.o.grepformat,
              open = not params.bang,
              open_height = 8,
              items_only = true,
            },
            -- We don't care to keep this around as long as most tasks
            { "on_complete_dispose", timeout = 30, require_view = {} },
            "default",
          },
        })
        task:start()
      end, { nargs = "*", bang = true, bar = true, complete = "file" })

      vim.api.nvim_create_user_command("Make", function(params)
        -- Insert args at the '$*' in the makeprg
        local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
        if num_subs == 0 then
          cmd = cmd .. " " .. params.args
        end
        local task = require("overseer").new_task({
          cmd = vim.fn.expandcmd(cmd),
          components = {
            { "on_output_quickfix", open = not params.bang, open_height = 8 },
            "unique",
            "default",
          },
        })
        task:start()
      end, {
        desc = "Run your makeprg as an Overseer task",
        nargs = "*",
        bang = true,
      })
    end,
  },
}
