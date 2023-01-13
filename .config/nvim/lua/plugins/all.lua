local p = require("p")
local ftplugin = p.require("ftplugin")

local pending_notifications = {}
local old_notify = vim.notify
vim.notify = function(...)
  table.insert(pending_notifications, { ... })
end

p.load("plenary.nvim")
p.load("nvim-treesitter")
p.load("nvim-treesitter-context")
p.load("nvim-treesitter-textobjects")
p.load("closetag")
p.load("resession.nvim")
p.load("comment.nvim").require("Comment").setup()
p.load("dressing.nvim").require("dressing", function(dressing)
  dressing.setup({
    input = {
      insert_only = false,
      -- relative = "editor",
      win_options = {
        sidescrolloff = 4,
      },
    },
  })
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
end)
p("firenvim", {
  post_config = "plugins.firenvim",
})
if vim.g.started_by_firenvim then
  p.load("firenvim")
end
p.load("editorconfig-vim")
p.load("lspkind-nvim")
p.load("lualine.nvim")
p("luasnip", {
  modules = { "^luasnip" },
  autocmds = {
    InsertEnter = { pattern = "*" },
  },
  req = "luasnip",
  post_config = "plugins.luasnip",
})
p.load("crates.nvim").require("crates").setup()
p("nvim-cmp", {
  modules = { "^cmp%." },
  autocmds = {
    InsertEnter = { pattern = "*" },
  },
  dependencies = { "luasnip" },
  req = "cmp",
  post_config = "plugins.completion",
})
p.load("nvim-cmp")
p.load("luv-vimdocs")
p.load("nightfox.nvim")
p.load("null-ls.nvim")
p("nvim-dap", {
  req = "dap",
  keymaps = {
    { "n", "<leader>dc", "<cmd>lua require'dap'.continue()<CR>", { desc = "[D]ebug [C]ontinue" } },
    { "n", "<leader>dj", "<cmd>lua require'dap'.step_over()<CR>", { desc = "[D]ebug step over" } },
    { "n", "<leader>di", "<cmd>lua require'dap'.step_into()<CR>", { desc = "[D]ebug step [I]nto" } },
    { "n", "<leader>do", "<cmd>lua require'dap'.step_out()<CR>", { desc = "[D]ebug step [O]ut" } },
    { "n", "<leader>dl", "<cmd>lua require'dap'.run_last()<CR>", { desc = "[D]ebug run [L]ast" } },
    { "n", "<leader>dr", "<cmd>lua require'dap'.repl.open()<CR>", { desc = "[D]ebug open [R]epl" } },
    { "n", "<leader>dq", "<cmd>lua require'dap'.terminate()<CR>", { desc = "[D]ebug [Q]uit" } },
  },
  post_config = "plugins.dap",
})
-- TODO need to manually load to make this work with overseer
-- p.load("nvim-dap")
p("nvim-jdtls", { filetypes = "java", modules = { "^jdtls" } })
p.load("nvim-lspconfig")
p.load("nvim-luaref")
if vim.g.nerd_font ~= false then
  p.load("nvim-web-devicons").require("nvim-web-devicons").setup({
    default = true,
  })
end
p.load("qf_helper.nvim").require("qf_helper").setup()
p("quickfix-reflector.vim", {
  autocmds = {
    QuickFixCmdPost = { pattern = "*" },
  },
})
p("scnvim", {
  filetypes = "supercollider",
  pre_config = function()
    vim.g.scnvim_no_mappings = 1
    vim.g.scnvim_eval_flash_repeats = 1
  end,
})
p.load("stickybuf.nvim")
p("suda.vim", {
  commands = { "SudaRead", "SudaWrite" },
})
p("tabular", { commands = { "Tabularize" } })
p.load("targets.vim")
p.load("telescope.nvim")
p.load("tokyonight.nvim")
p("vim-arduino", {
  filetypes = "arduino",
  pre_config = function()
    vim.g.arduino_serial_cmd = "picocom {port} -b {baud} -l"
  end,
})
p.load("vim-autoswap")
p.load("vim-endwise")
p.load("vim-eunuch")
p("vim-fugitive", {
  keymaps = {
    { "n", "<leader>gh", "<cmd>GitHistory<CR>", { desc = "[G]it [H]istory" } },
    { "n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "[G]it [B]lame" } },
    { "n", "<leader>gc", "<cmd>GBrowse!<CR>", { desc = "[G]it [C]opy link" } },
    { "v", "<leader>gc", ":GBrowse!<CR>", { desc = "[G]it [C]opy link" } },
  },
})
p.load("vim-fugitive")
vim.keymap.set("n", "<leader>gt", function()
  require("gitterm").toggle()
end, { desc = "[G]it [T]erminal interface" })
p.load("vim-repeat")
p.load("vim-rhubarb")
p.load("vim-startuptime")
p.load("vim-surround")
p.load("vim-vscode-snippets")

require("plugins.lualine")
require("plugins.telescope")
p("nvim-notify", {
  autocmds = {
    ColorScheme = { pattern = "*" },
  },
  post_config = function()
    -- We have to set this up after we apply our colorscheme
    vim.notify = old_notify
    p.require("notify", function(notify)
      vim.notify = notify
      notify.setup({
        stages = "fade",
        render = "minimal",
        top_down = false,
      })
    end)
    for _, args in ipairs(pending_notifications) do
      vim.notify(unpack(args))
    end
    pending_notifications = nil
  end,
})

p("pair-ls.nvim", {
  commands = { "Pair", "PairConnect" },
  req = "pair-ls",
  post_config = function(pairls)
    pairls.setup({
      cmd = { "pair-ls", "lsp" },
      -- cmd = { "pair-ls", "lsp", "-port", "8080" },
      -- cmd = { "pair-ls", "lsp", "-port", "8081" },
      -- cmd = { "pair-ls", "lsp", "-signal", "wss://localhost:8080" },
      -- cmd = { "pair-ls", "lsp", "-forward", "wss://localhost:8080" },
    })
  end,
})

local gkeep_bindings = {
  { "n", "<leader>m", "<CMD>GkeepEnter menu<CR>" },
  { "n", "<leader>l", "<CMD>GkeepEnter list<CR>" },
}
ftplugin.set("GoogleKeepList", {
  callback = function(bufnr)
    -- FIXME update the api for stickybuf
    vim.cmd("silent! PinBuffer")
  end,
  bindings = gkeep_bindings,
})
ftplugin.set("GoogleKeepMenu", ftplugin.get("GoogleKeepList"))
ftplugin.set("GoogleKeepNote", {
  bindings = vim.list_extend({
    { "n", "<leader>x", "<CMD>GkeepCheck<CR>" },
    { "n", "<leader>p", "<CMD>GkeepPopup<CR>" },
    { "n", "<leader>fl", "<CMD>Telescope gkeep link<CR>" },
  }, gkeep_bindings),
})
ftplugin.extend("norg", { bindings = gkeep_bindings })
p("gkeep.nvim", {
  keymaps = { { "n", "<leader>n", "<cmd>GkeepToggle<CR>", { desc = "[N]otes" } } },
  modules = { "^telescope._extensions.gkeep$" },
  autocmds = {
    BufReadPre = { pattern = "gkeep://*" },
  },
  pre_config = function()
    -- vim.g.gkeep_sync_dir = '~/notes'
    -- vim.g.gkeep_sync_archived = true
    vim.g.gkeep_log_levels = {
      gkeep = "debug",
      gkeepapi = "warning",
    }
  end,
})

p.load("oil.nvim").require("plugins.oil")

p.load("aerial.nvim").require("plugins.aerial")
p("lightspeed.nvim", {
  keymaps = {
    { "", "<leader>s", "<Plug>Lightspeed_omni_s", { desc = "Lightspeed search" } },
    { "", "gs", "<Plug>Lightspeed_omni_s", { desc = "Lightspeed search" } },
  },
  pre_config = function()
    vim.g.lightspeed_no_default_keymaps = true
  end,
  req = "lightspeed",
  post_config = function(lightspeed)
    lightspeed.setup({
      jump_to_unique_chars = false,
      safe_labels = {},
    })
  end,
})
p.require("tags", function(tags)
  tags.setup({
    on_attach = function(bufnr)
      vim.keymap.set("n", "<C-]>", tags.goto_definition, { buffer = bufnr, desc = "Goto tag" })
    end,
  })
end)
-- Only change the clipboard if we're in a SSH session
if os.getenv("SSH_CLIENT") then
  p.load("nvim-osc52").require("osc52", function(osc52)
    local function copy(lines, _)
      osc52.copy(table.concat(lines, "\n"))
    end

    local function paste()
      return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end

    vim.g.clipboard = {
      name = "osc52",
      copy = { ["+"] = copy, ["*"] = copy },
      paste = { ["+"] = paste, ["*"] = paste },
    }
  end)
end
p.load("overseer.nvim")
p.load("nvim-config-local").require("config-local", function(config_local)
  config_local.setup({
    config_files = { ".nvimrc.lua", ".vimrc.lua", ".nvimrc" },
    autocommands_create = true,
    commands_create = true,
    silent = false,
    lookup_parents = true,
  })
end)

p.load("neotest", "neotest-jest", "neotest-plenary", "neotest-python")
require("plugins.neotest")

p.require("overseer", function(overseer)
  overseer.setup({
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
  })
  vim.api.nvim_create_user_command("OverseerDebugParser", 'lua require("overseer").debug_parser()', {})
  vim.keymap.set("n", "<leader>oo", "<cmd>OverseerToggle<CR>")
  vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>")
  vim.keymap.set("n", "<leader>oc", "<cmd>OverseerRunCmd<CR>")
  vim.keymap.set("n", "<leader>ol", "<cmd>OverseerLoadBundle<CR>")
  vim.keymap.set("n", "<leader>ob", "<cmd>OverseerBuild<CR>")
  vim.keymap.set("n", "<leader>od", "<cmd>OverseerQuickAction<CR>")
  vim.keymap.set("n", "<leader>os", "<cmd>OverseerTaskAction<CR>")
end)
p.load("nvim-hlslens").require("plugins.hlslens")

p("nvim-FeMaco.lua", {
  commands = { "FeMaco" },
  req = "femaco",
  post_config = function(femaco)
    femaco.setup()
  end,
})

require("plugins.ccc")

p.require("quick_action", function(quick_action)
  quick_action.set_keymap("n", "<CR>", "menu")
  quick_action.add("menu", {
    name = "Show diagnostics",
    condition = function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
      return not vim.tbl_isempty(
        vim.diagnostic.get(0, { lnum = lnum, severity = { min = vim.diagnostic.severity.WARN } })
      )
    end,
    action = function()
      vim.diagnostic.open_float(0, { scope = "line", border = "rounded" })
    end,
  })
end)
p.load("three.nvim").require("plugins.three")
p("fidget.nvim", {
  req = "fidget",
  modules = { "^fidget" },
  post_config = function(fidget)
    fidget.setup({
      text = {
        spinner = "dots",
      },
      window = {
        relative = "editor",
      },
    })
  end,
})
p.require("plugins.resession")

require("plugins.distant")
p("playground", {
  commands = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
})

-- vim-matchup
p.load("vim-matchup")
vim.g.matchup_surround_enabled = 1
vim.g.matchup_matchparen_nomode = "i"
vim.g.matchup_matchparen_deferred = 1
vim.g.matchup_matchparen_deferred_show_delay = 400
vim.g.matchup_matchparen_deferred_hide_delay = 400
vim.g.matchup_matchparen_offscreen = {}
vim.keymap.set({ "n", "x" }, "[[", "<plug>(matchup-[%)")
vim.keymap.set({ "n", "x" }, "]]", "<plug>(matchup-]%)")
