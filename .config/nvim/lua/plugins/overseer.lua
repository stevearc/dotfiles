local function has_output_win()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[winid].is_quickrun_output then
      return true
    end
  end
  return false
end

---@param args? string
local function run_current_file(args)
  local overseer = require("overseer")
  vim.cmd.update()
  local bufnr = vim.api.nvim_get_current_buf()

  ---@type overseer.Task|nil
  local task = overseer.list_tasks({ filter = function(t) return t.metadata.quickrun_bufnr == bufnr end })[1]
  if args and task then
    -- vim.defer_fn(function() task:dispose() end, 1000)
    task:dispose(true)
    task = nil
  end

  if not task then
    local path = vim.api.nvim_buf_get_name(0)
    local cmd
    if vim.fn.executable(path) == 1 then
      cmd = { path }
    elseif vim.bo.filetype == "python" then
      cmd = { "python", path }
    elseif vim.bo.filetype == "sh" then
      cmd = { "bash", path }
    else
      vim.notify("Not sure how to run file", vim.log.levels.ERROR)
      return
    end

    if args then
      cmd = table.concat(cmd, " ") .. " " .. args
    end

    task = overseer.new_task({
      cmd = cmd,
      metadata = {
        quickrun_bufnr = bufnr,
      },
    })
    task:remove_component("on_complete_dispose")
  end

  task:restart(true)

  if not has_output_win() then
    vim.cmd.split()
    overseer.create_task_output_view(0, {
      list_task_opts = {
        filter = function(task) return task.metadata.quickrun_bufnr == bufnr end,
      },
      select = function(self, tasks, task_under_cursor) return tasks[1] end,
    })
    vim.w.is_quickrun_output = true
  end
end

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
      "OverseerTestOutput",
    },
    keys = {
      { "<leader>oo", "<cmd>OverseerToggle!<CR>", mode = "n", desc = "[O]verseer [O]pen" },
      { "<leader>or", "<cmd>OverseerRun<CR>", mode = "n", desc = "[O]verseer [R]un" },
      { "<leader>os", "<cmd>OverseerShell<CR>", mode = "n", desc = "[O]verseer [S]hell" },
      { "<leader>ot", "<cmd>OverseerTaskAction<CR>", mode = "n", desc = "[O]verseer [T]ask action" },
      { "<leader>e", function() run_current_file() end, mode = "n", desc = "[E]xecute file" },
      {
        "<leader>E",
        function()
          vim.ui.input({ prompt = "args" }, function(args)
            if args then
              run_current_file(args)
            end
          end)
        end,
        mode = "n",
        desc = "[E]xecute file with parameters",
      },
      {
        "<leader>od",
        function()
          local overseer = require("overseer")
          local task_list = require("overseer.task_list")
          local tasks = overseer.list_tasks({
            sort = task_list.sort_finished_recently,
            include_ephemeral = true,
          })
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            local most_recent = tasks[1]
            overseer.run_action(most_recent)
          end
        end,
        mode = "n",
        desc = "[O]verseer [D]o quick action",
      },
    },
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {
      dap = false,
      log_level = vim.log.levels.TRACE,
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
      experimental_wrap_builtins = {
        enabled = false,
        partial_condition = {
          noop = function(cmd, caller, opts) return true end,
        },
      },
      post_setup = {},
    },
    init = function() vim.cmd.cnoreabbrev("OS OverseerShell") end,
    config = function(_, opts)
      local partial = opts.experimental_wrap_builtins.partial_condition
      opts.experimental_wrap_builtins.condition = function(cmd, caller, opts)
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
