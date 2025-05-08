return {
  {
    "stevearc/resession.nvim",
    lazy = true,
    opts = {
      extensions = {
        overseer = {
          filter = {
            status = { "RUNNING" },
          },
        },
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = {
      "Grep",
      "Make",
      "OverseerShell",
      "OverseerOpen",
      "OverseerRun",
      "OverseerToggle",
    },
    keys = {
      { "<leader>oo", "<cmd>OverseerToggle!<CR>", mode = "n", desc = "[O]verseer [O]pen" },
      { "<leader>or", "<cmd>OverseerRun<CR>", mode = "n", desc = "[O]verseer [R]un" },
      { "<leader>os", "<cmd>OverseerShell<CR>", mode = "n", desc = "[O]verseer [S]hell" },
      { "<leader>od", "<cmd>OverseerQuickAction<CR>", mode = "n", desc = "[O]verseer [D]o quick action" },
      { "<leader>ot", "<cmd>OverseerTaskAction<CR>", mode = "n", desc = "[O]verseer [T]ask action" },
    },
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {
      strategy = { "jobstart" },
      dap = false,
      log_level = vim.log.levels.TRACE,
      wrap_builtins = {
        enabled = true,
        partial_condition = {
          noop = function(cmd, caller, opts) return true end,
        },
      },
      component_aliases = {
        default = {
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
    init = function() vim.cmd.cnoreabbrev("OS OverseerShell") end,
    config = function(_, opts)
      local partial = opts.wrap_builtins.partial_condition
      opts.wrap_builtins.condition = function(cmd, caller, opts)
        for _, v in pairs(partial) do
          if not v(cmd, caller, opts) then
            return false
          end
        end
        return true
      end
      local overseer = require("overseer")
      overseer.setup(opts)
      for _, cb in pairs(opts.post_setup) do
        cb()
      end
      vim.api.nvim_create_user_command("OverseerTestOutput", function(params)
        vim.cmd.tabnew()
        vim.bo.bufhidden = "wipe"
        overseer.create_task_output_view(0, {
          select = function(self, tasks)
            for _, task in ipairs(tasks) do
              if task.metadata.neotest_group_id then
                return task
              end
            end
            self:dispose()
          end,
        })
      end, {
        desc = "Open a new tab that displays the output of the most recent test",
      })
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
