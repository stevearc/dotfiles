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

    local group = vim.api.nvim_create_augroup("LspProgress", {})
    -- LSP progress
    ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
    local progress = vim.defaulttable()
    vim.api.nvim_create_autocmd("LspProgress", {
      group = group,
      ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
        if not client or type(value) ~= "table" then
          return
        end
        local p = progress[client.id]

        for i = 1, #p + 1 do
          if i == #p + 1 or p[i].token == ev.data.params.token then
            p[i] = {
              token = ev.data.params.token,
              msg = ("[%3d%%] %s%s"):format(
                value.kind == "end" and 100 or value.percentage or 100,
                value.title or "",
                value.message and (" **%s**"):format(value.message) or ""
              ),
              done = value.kind == "end",
            }
            break
          end
        end

        local msg = {} ---@type string[]
        progress[client.id] = vim.tbl_filter(function(v) return table.insert(msg, v.msg) or not v.done end, p)
        local final_message = vim.tbl_isempty(progress[client.id])

        local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        vim.notify(table.concat(msg, "\n"), "info", {
          id = "lsp_progress:" .. tostring(client.id),
          title = client.name,
          timeout = final_message,
          history = final_message,
          opts = function(notif)
            notif.icon = final_message and " " or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
          end,
        })
      end,
    })
    vim.api.nvim_create_autocmd("LspDetach", {
      group = group,
      ---@param ev {data: {client_id: integer}}
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client or client:is_stopped() then
          progress[ev.data.client_id] = nil
          Snacks.notifier.hide("lsp_progress:" .. tostring(ev.data.client_id))
        end
      end,
    })
  end,
}
