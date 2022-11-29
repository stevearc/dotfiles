_G.stevearc = {}

-- Profiling
local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  require("profile").instrument_autocmds()
  if should_profile:lower():match("^start") then
    require("profile").start("*")
  else
    require("profile").instrument("*")
  end
end

local function toggle_profile()
  local prof = require("profile")
  if prof.is_recording() then
    prof.stop()
    vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
      if filename then
        prof.export(filename)
        vim.notify(string.format("Wrote %s", filename))
      end
    end)
  else
    prof.start("*")
  end
end
vim.keymap.set("", "<f1>", toggle_profile)

function _G.safe_require(...)
  local args = { ... }
  local mods = {}
  local first_mod
  for _, arg in ipairs(args) do
    if type(arg) == "function" then
      arg(unpack(mods))
      break
    end
    local ok, mod = pcall(require, arg)
    if ok then
      if not first_mod then
        first_mod = mod
      end
      table.insert(mods, mod)
    else
      -- Don't bother notifying if we're in a nvenv
      if not os.getenv("NVENV") then
        vim.notify_once(string.format("Missing module: %s", arg), vim.log.levels.WARN)
      end
      -- Return a dummy item that returns functions, so we can do things like
      -- safe_require("module").setup()
      local dummy = {}
      setmetatable(dummy, {
        __call = function()
          return dummy
        end,
        __index = function()
          return dummy
        end,
      })
      return dummy
    end
  end
  return first_mod
end

-- Patch vim.keymap.set so that it reports errors
local _keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  local _rhs = rhs
  if type(rhs) == "function" then
    rhs = function()
      local ok, res_or_err = pcall(_rhs)
      if ok then
        return res_or_err
      else
        vim.api.nvim_echo({ { res_or_err, "Error" } }, true, {})
      end
    end
  end
  _keymap_set(mode, lhs, rhs, opts)
end

vim.g.python3_host_prog = os.getenv("HOME") .. "/.envs/py3/bin/python"
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local/site/pack/*/start/*")
local aug = vim.api.nvim_create_augroup("StevearcNewConfig", {})

local ftplugin = safe_require("ftplugin")
vim.keymap.set("n", "<f2>", [[<cmd>lua require'plenary.profile'.start("profile.log", {flame = true})<cr>]])
vim.keymap.set("n", "<f3>", [[<cmd>lua require'plenary.profile'.stop()<cr>]])

vim.g.nerd_font = true
vim.g.debug_treesitter = false
vim.g.sidebar_filetypes = { "dagger", "aerial", "OverseerList", "neotest-summary" }

-- Space is leader
vim.g.mapleader = " "

-- Options
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.o.expandtab = true -- Turn tabs into spaces
vim.o.formatoptions = "rqnlj"
vim.o.gdefault = true -- Use 'g' flag by default with :s/foo/bar
vim.o.ignorecase = true
vim.o.laststatus = 3 -- Global statusline
vim.o.mouse = "a" -- Enable use of mouse
vim.o.path = "**" -- Use a recursive path (for :find)
vim.o.previewheight = 5
vim.o.pumblend = 10 -- Transparency for popup-menu
vim.o.ruler = true -- Show the row, column of the cursor
vim.o.shiftwidth = 2
vim.opt.shortmess:append("c") -- for nvim-cmp
vim.opt.shortmess:append("I") -- Hide the startup screen
vim.opt.shortmess:append("A") -- Ignore swap file messages
vim.opt.shortmess:append("a") -- Shorter message formats
vim.o.showmatch = true -- When a bracket is inserted, briefly jump to the matching one
vim.o.showtabline = 2 -- Always show tab line
vim.o.smartcase = true
vim.o.softtabstop = 2
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.switchbuf = "useopen,uselast" -- Don't reopen buffers
vim.o.synmaxcol = 300 -- Don't syntax highlight long lines
vim.o.tabstop = 2
vim.o.textwidth = 100 -- Line width of 100
vim.o.updatetime = 400 -- CursorHold time default is 4s. Way too long
vim.o.whichwrap = "h,l" -- allow cursor to wrap to next/prev line
vim.opt.wildignore:append(
  "*.png,*.jpg,*.jpeg,*.gif,*.wav,*.aiff,*.dll,*.pdb,*.mdb,*.so,*.swp,*.zip,*.gz,*.bz2,*.meta,*.svg,*.cache,*/.git/*"
)
vim.o.wildmenu = true
vim.o.wildmode = "longest,list,full"

-- Window options
vim.opt.list = true -- show whitespace
vim.opt.listchars = {
  nbsp = "⦸", -- CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
  extends = "»", -- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
  precedes = "«", -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
  tab = "▷⋯", -- WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7) + MIDLINE HORIZONTAL ELLIPSIS (U+22EF, UTF-8: E2 8B AF)
}
vim.o.number = true -- Except for current line
vim.o.relativenumber = true -- Relative line numbers
vim.opt.showbreak = "↳ " -- DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)

vim.filetype.add({
  extension = {
    sky = "python", -- starlark
  },
  filename = {
    [".nvimrc"] = "lua",
  },
  pattern = {
    [".*/%.vscode/.*%.json"] = "json5", -- These json files frequently have comments
  },
})

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  desc = "Highlight the cursor line in the active window",
  pattern = "*",
  command = "setlocal cursorline",
  group = aug,
})
vim.api.nvim_create_autocmd("WinLeave", {
  desc = "Clear the cursor line highlight when leaving a window",
  pattern = "*",
  command = "setlocal nocursorline",
  group = aug,
})

-- built-in ftplugins should not change my keybindings
vim.g.no_plugin_maps = true
vim.cmd([[
syntax enable
syntax on
filetype plugin on
filetype plugin indent on
]])

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Return to last edit position when opening files",
  pattern = "*",
  command = [[if line("'\"") > 0 && line("'\"") <= line("$") && expand('%:t') != 'COMMIT_EDITMSG' | exe "normal! g`\"" | endif]],
  group = aug,
})

-- Add bash shortcuts for command line
vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-b>", "<Left>")
vim.keymap.set("c", "<C-f>", "<Right>")
vim.keymap.set("c", "<C-d>", "<Delete>")
vim.keymap.set("c", "<M-b>", "<S-Left>")
vim.keymap.set("c", "<M-f>", "<S-Right>")
vim.keymap.set("c", "<M-d>", "<S-right><Delete>")
vim.keymap.set("c", "<Esc>b", "<S-Left>")
vim.keymap.set("c", "<Esc>f", "<S-Right>")
vim.keymap.set("c", "<Esc>d", "<S-right><Delete>")
vim.keymap.set("c", "<C-g>", "<C-c>")

-- Save jumps > 5 lines to the jumplist
-- Jumps <= 5 respect line wraps
vim.keymap.set("n", "j", [[(v:count > 5 ? "m'" . v:count . 'j' : 'gj')]], { expr = true })
vim.keymap.set("n", "k", [[(v:count > 5 ? "m'" . v:count . 'k' : 'gk')]], { expr = true })

-- Paste last text that was yanked, not deleted
vim.keymap.set("n", "<leader>p", '"0p')
vim.keymap.set("n", "<leader>P", '"0P')

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinNew", "VimResized" }, {
  desc = "Always keep the cursor vertically centered",
  pattern = "*,*.*",
  command = 'let &l:scrolloff=1+winheight(win_getid())/2")',
  group = aug,
})

vim.g.treesitter_languages = "all"
vim.g.treesitter_languages_blacklist = { "supercollider", "phpdoc" }

-- Start with folds open
vim.o.foldlevelstart = 99
vim.o.foldlevel = 99
-- Disable fold column
vim.o.foldcolumn = "0"
function stevearc.foldtext()
  local line = vim.api.nvim_buf_get_lines(0, vim.v.foldstart - 1, vim.v.foldstart, true)[1]
  local idx = vim.v.foldstart + 1
  while string.find(line, "^%s*@") or string.find(line, "^%s*$") do
    line = vim.api.nvim_buf_get_lines(0, idx - 1, idx, true)[1]
    idx = idx + 1
  end
  local icon = "▼"
  if vim.g.nerd_font then
    icon = " "
  end
  local padding = string.rep(" ", string.find(line, "[^%s]") - 1)
  return string.format("%s%s %s   %d", padding, icon, line, vim.v.foldend - vim.v.foldstart + 1)
end
vim.opt.fillchars = {
  fold = " ",
  vert = "┃",
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
}
vim.o.foldtext = [[v:lua.stevearc.foldtext()")]]

-- Use my universal clipboard tool to copy with <leader>y
vim.keymap.set("n", "<leader>y", '<cmd>call system("clip", @0)<CR>')

-- Map leader-r to do a global replace of a word
vim.keymap.set("n", "<leader>r", [[*N:s//<C-R>=expand("<cword>")<CR>]])

-- Expand %% to current directory in command mode
vim.cmd([[
cabbr <expr> %% expand('%:p:h')
]])

vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Reload files from disk when we focus vim",
  pattern = "*",
  command = "if getcmdwintype() == '' | checktime | endif",
  group = aug,
})
vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Every time we enter an unmodified buffer, check if it changed on disk",
  pattern = "*",
  command = "if &buftype == '' && !&modified | exec 'checktime ' . expand('<abuf>') | endif",
  group = aug,
})

-- Enter paste mode with <C-v> in insert mode
vim.keymap.set("i", "<C-v>", "<cmd>set paste<CR>")
vim.api.nvim_create_autocmd("InsertLeave", {
  desc = "Leave paste mode when leaving insert",
  pattern = "*",
  command = "set nopaste",
  group = aug,
})

-- Close the scratch preview automatically
vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave" }, {
  desc = "Close the popup-menu automatically",
  pattern = "*",
  command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
  group = aug,
})

-- BASH-style movement in insert mode
vim.keymap.set("i", "<C-a>", "<C-o>^")
vim.keymap.set("i", "<C-e>", "<C-o>$")

vim.cmd("command! GitHistory Git! log -- %")

vim.g.scnvim_no_mappings = 1
vim.g.scnvim_eval_flash_repeats = 1

if vim.fn.has("win32") ~= 0 then
  vim.o.shell = "powershell"
  vim.opt.shellcmdflag:remove("command")
  vim.o.shellquote = '"'
  vim.o.shellxquote = ""
end

-- This lets our bash aliases know to use nvr instead of nvim
vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername

-- For quick-n-dirty inspection
function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
  return ...
end

local on_enter_mods = { "plugins.lsp", "plugins.completion", "plugins.luasnip" }
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Complete config setup after VimEnter",
  group = aug,
  callback = function()
    vim.defer_fn(function()
      for _, mod in ipairs(on_enter_mods) do
        require(mod)
      end
    end, 100)
  end,
})
local function delay_setup(module) end

-- quickfix
vim.cmd([[
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])
]])
vim.keymap.set("n", "<C-N>", "<cmd>QNext<CR>")
vim.keymap.set("n", "<C-P>", "<cmd>QPrev<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>QFToggle!<CR>")
vim.keymap.set("n", "<leader>l", "<cmd>LLToggle!<CR>")

local pending_notifications = {}
local old_notify = vim.notify
vim.notify = function(...)
  table.insert(pending_notifications, { ... })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  once = true,
  callback = function()
    -- We have to set this up after we apply our colorscheme
    vim.notify = old_notify
    safe_require("notify", function(notify)
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

safe_require("pair-ls").setup({
  cmd = { "pair-ls", "lsp" },
  -- cmd = { "pair-ls", "lsp", "-port", "8080" },
  -- cmd = { "pair-ls", "lsp", "-port", "8081" },
  -- cmd = { "pair-ls", "lsp", "-signal", "wss://localhost:8080" },
  -- cmd = { "pair-ls", "lsp", "-forward", "wss://localhost:8080" },
})
safe_require("qf_helper").setup()
safe_require("Comment").setup()
safe_require("crates").setup()
safe_require("dressing").setup({
  input = {
    insert_only = false,
    -- relative = "editor",
  },
})

vim.keymap.set("n", "<leader>n", "<cmd>GkeepToggle<CR>")
-- vim.g.gkeep_sync_dir = '~/notes'
-- vim.g.gkeep_sync_archived = true
vim.g.gkeep_log_levels = {
  gkeep = "debug",
  gkeepapi = "warning",
}
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

safe_require("aerial", function(aerial)
  ftplugin.extend("aerial", {
    ignore_win_opts = true,
  })
  aerial.setup({
    show_guides = true,
    layout = {
      max_width = { 80, 0.2 },
      default_direction = "prefer_left",
      -- placement = "edge",
    },
    -- attach_mode = "global",
    highlight_on_hover = true,
    close_automatic_events = {
      -- "unfocus",
      -- "switch_buffer",
      -- "unsupported",
    },
    -- open_automatic = true,
    -- highlight_on_jump = false,
    link_folds_to_tree = true,
    link_tree_to_folds = true,
    manage_folds = {
      ["_"] = true,
    },
    nerd_font = vim.g.nerd_font,

    -- backends = { "treesitter", "markdown" },
    -- backends = { "lsp", "treesitter" },
    lazy_load = true,
    -- backends = { "lsp", "treesitter", "markdown" },
    -- filter_kind = false,
    on_attach = function(bufnr)
      vim.keymap.set({ "n", "v" }, "{", aerial.prev, { buffer = bufnr })
      vim.keymap.set({ "n", "v" }, "}", aerial.next, { buffer = bufnr })
    end,
    keymaps = {
      ["<"] = "actions.tree_decrease_fold_level",
      [">"] = "actions.tree_increase_fold_level",
    },
  })
  vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
  vim.keymap.set({ "n", "v" }, "[s", aerial.prev)
  vim.keymap.set({ "n", "v" }, "]s", aerial.next)
  vim.keymap.set({ "n", "v" }, "[u", aerial.prev_up)
  vim.keymap.set({ "n", "v" }, "]u", aerial.next_up)
end)

vim.g.lightspeed_no_default_keymaps = true
safe_require("lightspeed", function(lightspeed)
  lightspeed.setup({
    jump_to_unique_chars = false,
    safe_labels = {},
  })
  -- Not sure which of these mappings I prefer yet
  vim.keymap.set("", "<leader>s", "<Plug>Lightspeed_omni_s")
  vim.keymap.set("", "gs", "<Plug>Lightspeed_omni_s")
end)
safe_require("tags", function(tags)
  tags.setup({
    on_attach = function(bufnr)
      -- vim.keymap.set("n", "gd", tags.goto_definition, { buffer = bufnr })
      vim.keymap.set("n", "<C-]>", tags.goto_definition, { buffer = bufnr })
    end,
  })
end)
safe_require("osc52", function(osc52)
  local function copy(lines, _)
    osc52.copy(table.concat(lines, "\n"))
  end

  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  -- Only change the clipboard if we're in a SSH session
  if os.getenv("SSH_CLIENT") then
    vim.g.clipboard = {
      name = "osc52",
      copy = { ["+"] = copy, ["*"] = copy },
      paste = { ["+"] = paste, ["*"] = paste },
    }
  end
end)
safe_require("resession", function(resession)
  resession.setup({
    autosave = {
      enabled = true,
      notify = false,
    },
    tab_buf_filter = function(tabpage, bufnr)
      local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
      return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
    end,
    extensions = { aerial = {}, overseer = {}, quickfix = {}, three = {} },
  })
  vim.keymap.set("n", "<leader>ss", resession.save)
  vim.keymap.set("n", "<leader>st", function()
    resession.save_tab()
  end)
  vim.keymap.set("n", "<leader>so", resession.load)
  vim.keymap.set("n", "<leader>sl", function()
    resession.load(nil, { reset = false })
  end)
  vim.keymap.set("n", "<leader>sd", resession.delete)
  vim.api.nvim_create_user_command("SessionDetach", function()
    resession.detach()
  end, {})
  vim.keymap.set("n", "ZZ", function()
    resession.save("__quicksave__", { notify = false })
    vim.cmd("wa")
    vim.cmd("qa")
  end)

  vim.api.nvim_create_autocmd("VimEnter", {
    group = aug,
    callback = function()
      if vim.tbl_contains(resession.list(), "__quicksave__") then
        vim.defer_fn(function()
          resession.load("__quicksave__", { attach = false })
          local ok, err = pcall(resession.delete, "__quicksave__")
          if not ok then
            vim.notify(string.format("Error deleting quicksave session: %s", err), vim.log.levels.WARN)
          end
        end, 50)
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      resession.save("last")
    end,
  })
end)
safe_require("config-local").setup({
  config_files = { ".vimrc.lua", ".nvimrc" },
  autocommands_create = true,
  commands_create = true,
  silent = false,
  lookup_parents = true,
})

-- Todo:
-- * Bug: Running tests on directory doesn't work if directory not in tree (but tree has subdirectories)
-- * Bug: No output or debug info if test fails to run (e.g. try running tests in cpython)
-- * Bug: Sometimes issues with running python tests (dir position stuck in running state)
-- * Bug: Files shouldn't appear in summary if they contain no tests (e.g. python file named 'test_*.py')
-- * Bug: dir/file/namespace status should be set by children
-- * Bug: Run last test doesn't work with marked tests (if ran all marked last)
-- * Feat: If summary tree only has a single (file/dir) child, merge the display
-- * Feat: Different bindings for expand/collapse
-- * Feat: Can collapse tree on a child node
-- * Feat: Can't rerun failed tests
-- * Feat: Configure adapters & discovery on a per-directory basis
-- Investigate:
-- * Does neotest have ability to throttle groups of individual test runs?
-- * Tangential, but also check out https://github.com/andythigpen/nvim-coverage
safe_require(
  "neotest",
  "neotest-python",
  "neotest-plenary",
  "neotest-jest",
  function(neotest, python_adapter, plenary_adapter, jest_adapter)
    -- require("neotest.logging"):set_level("trace")
    neotest.setup({
      adapters = {
        python_adapter({
          dap = { justMyCode = false },
        }),
        plenary_adapter,
        jest_adapter({
          cwd = jest_adapter.root,
        }),
      },
      discovery = {
        enabled = false,
      },
      consumers = {
        overseer = safe_require("neotest.consumers.overseer"),
      },
      summary = {
        mappings = {
          attach = "a",
          expand = "l",
          expand_all = "L",
          jumpto = "gf",
          output = "o",
          run = "<C-r>",
          short = "p",
          stop = "u",
        },
      },
      icons = {
        passed = " ",
        running = " ",
        failed = " ",
        unknown = " ",
        running_animated = vim.tbl_map(function(s)
          return s .. " "
        end, { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }),
      },
      diagnostic = {
        enabled = true,
      },
      output = {
        enabled = true,
        open_on_run = false,
      },
      status = {
        enabled = true,
      },
    })
    vim.keymap.set("n", "<leader>tn", function()
      neotest.run.run({})
    end)
    vim.keymap.set("n", "<leader>tt", function()
      neotest.run.run({ vim.api.nvim_buf_get_name(0) })
    end)
    vim.keymap.set("n", "<leader>ta", function()
      for _, adapter_id in ipairs(neotest.run.adapters()) do
        neotest.run.run({ suite = true, adapter = adapter_id })
      end
    end)
    vim.keymap.set("n", "<leader>tl", function()
      neotest.run.run_last()
    end)
    vim.keymap.set("n", "<leader>td", function()
      neotest.run.run({ strategy = "dap" })
    end)
    vim.keymap.set("n", "<leader>tp", function()
      neotest.summary.toggle()
    end)
    vim.keymap.set("n", "<leader>to", function()
      neotest.output.open({ short = true })
    end)
  end
)

safe_require("overseer", function(overseer)
  overseer.setup({
    strategy = { "jobstart", preserve_output = true },
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
safe_require("hlslens", function(hlslens)
  hlslens.setup({
    calm_down = true,
    nearest_only = true,
  })

  vim.keymap.set("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]])
  vim.keymap.set("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]])

  -- Fix * and # behavior to respect smartcase
  vim.keymap.set(
    "n",
    "*",
    [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]]
  )
  vim.keymap.set(
    "n",
    "#",
    [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]]
  )
  vim.keymap.set(
    "n",
    "g*",
    [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]]
  )
  vim.keymap.set(
    "n",
    "g#",
    [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]]
  )
end)

safe_require("femaco").setup()

safe_require("ccc", function(ccc)
  ccc.setup({
    inputs = {
      ccc.input.hsl,
      ccc.input.rgb,
      -- ccc.input.cmyk,
    },
  })
  safe_require("quick_action").add("<CR>", {
    name = "Pick color",
    condition = function()
      local cword = vim.fn.expand("<cword>"):lower()
      local match = cword:match("^#([a-f0-9]+)$") or cword:match("^[a-f0-9]+$")
      return match and (match:len() == 6 or match:len() == 3)
    end,
    action = function()
      vim.cmd("CccPick")
    end,
  })
end)

-- Diagnostics
safe_require("quick_action").add("<CR>", {
  name = "Show diagnostics",
  condition = function()
    return not vim.tbl_isempty(
      vim.diagnostic.get(
        0,
        { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1, severity = { min = vim.diagnostic.severity.WARN } }
      )
    )
  end,
  action = function()
    vim.diagnostic.open_float(0, { scope = "line", border = "rounded" })
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Pin buffer to window if opened from remote",
  pattern = "*",
  callback = function()
    if not vim.w.is_remote then
      return
    end
    if not vim.w._remote_entered then
      vim.w._remote_entered = true
      vim.cmd([[silent! PinBuffer]])
      vim.bo.bufhidden = "wipe"
    end
  end,
  group = aug,
})
safe_require("three", function(three)
  local is_windows = vim.loop.os_uname().version:match("Windows")

  local sep = is_windows and "\\" or "/"
  three.setup({
    projects = {
      filter_dir = function(dir)
        local dotgit = dir .. sep .. ".git"
        if vim.fn.isdirectory(dotgit) == 1 or vim.fn.filereadable(dotgit) == 1 then
          return true
        end
        -- If this is the child directory of a .git directory, ignore
        return vim.fn.finddir(".git", dir .. ";") == ""
      end,
    },
  })
  vim.keymap.set("n", "L", three.next, { desc = "Next buffer" })
  vim.keymap.set("n", "H", three.prev, { desc = "Previous buffer" })
  vim.keymap.set("n", "<C-l>", three.move_right, { desc = "Move buffer right" })
  vim.keymap.set("n", "<C-h>", three.move_left, { desc = "Move buffer left" })
  vim.keymap.set("n", "<C-j>", three.wrap(three.next_tab, { wrap = true }, { desc = "[G]oto next [T]ab" }))
  vim.keymap.set("n", "<C-k>", three.wrap(three.prev_tab, { wrap = true }, { desc = "[G]oto prev [T]ab" }))
  for i = 1, 9 do
    vim.keymap.set("n", "<leader>" .. i, three.wrap(three.jump_to, i))
  end
  vim.keymap.set("n", "<leader>`", three.wrap(three.next, { delta = 100 }))
  vim.keymap.set("n", "<leader>0", three.wrap(three.jump_to, 10))
  vim.keymap.set("n", "<leader>c", three.smart_close, { desc = "Smart [c]lose" })
  vim.keymap.set("n", "<leader>C", three.close_buffer, { desc = "[C]lose buffer" })
  vim.keymap.set("n", "<leader>bh", three.hide_buffer, { desc = "[B]uffer [H]ide" })
  vim.keymap.set("n", "<leader>bp", three.toggle_pin, { desc = "[B]uffer [P]in" })
  vim.keymap.set("n", "<leader>bi", three.toggle_pin, { desc = "[B]uffer P[i]n" })
  vim.keymap.set("n", "<leader>bm", function()
    vim.ui.input({ prompt = "Move buffer to:" }, function(idx)
      idx = idx and tonumber(idx)
      if idx then
        three.move_buffer(idx)
      end
    end)
  end, { desc = "[B]uffer [M]ove" })
  vim.keymap.set("n", "<C-w><C-t>", "<cmd>tabclose<CR>", { desc = "Close tab" })
  vim.keymap.set("n", "<C-w><C-b>", three.clone_tab, { desc = "Clone tab" })
  vim.keymap.set("n", "<C-w><C-n>", "<cmd>tabnew | set nobuflisted<CR>", { desc = "New tab" })
  vim.keymap.set("n", "<C-w>`", three.toggle_scope_by_dir, { desc = "Toggle tab scoping by directory" })
  vim.api.nvim_create_user_command("BufCloseAll", function()
    three.close_all_buffers()
  end, {})
  vim.api.nvim_create_user_command("BufCloseAllButCurrent", function()
    three.close_all_buffers(function(info)
      return info.bufnr ~= vim.api.nvim_get_current_buf()
    end)
  end, {})
  vim.api.nvim_create_user_command("BufCloseAllButPinned", function()
    three.close_all_buffers(function(info)
      return not info.pinned
    end)
  end, {})
  vim.api.nvim_create_user_command("BufHideAll", function()
    three.hide_all_buffers()
  end, {})
  vim.api.nvim_create_user_command("BufHideAllButCurrent", function()
    three.hide_all_buffers(function(info)
      return info.bufnr ~= vim.api.nvim_get_current_buf()
    end)
  end, {})
  vim.api.nvim_create_user_command("BufHideAllButPinned", function()
    three.hide_all_buffers(function(info)
      return not info.pinned
    end)
  end, {})

  vim.keymap.set("n", "<C-w>+", function()
    local enabled = three.toggle_win_resize()
    vim.notify("Window resizing " .. (enabled and "ENABLED" or "DISABLED"))
  end, {})
  vim.keymap.set("n", "<C-w>z", "<cmd>resize | vertical resize<CR>", {})

  vim.keymap.set("n", "<leader>fp", three.open_project, { desc = "[F]ind [P]roject" })
  vim.api.nvim_create_user_command("ProjectDelete", function()
    three.remove_project()
  end, {})
end)
safe_require("fidget").setup({
  text = {
    spinner = "dots",
  },
  window = {
    relative = "editor",
  },
})
safe_require(
  "lir",
  "lir.actions",
  "lir.mark.actions",
  "lir.clipboard.actions",
  function(lir, actions, mark_actions, clipboard_actions)
    vim.keymap.set("n", "-", function()
      require("lir.float").init()
    end)
    vim.keymap.set("n", "_", function()
      require("lir.float").init(".")
    end)
    local function close_float()
      if vim.api.nvim_win_get_config(0).relative ~= "" then
        vim.api.nvim_win_close(0, true)
      end
    end
    local lvim = require("lir.vim")
    local function open_terminal()
      local ctx = lvim.get_context()
      vim.cmd(string.format("lcd %s", ctx.dir))
      vim.cmd("terminal")
    end
    local function find_files()
      local ctx = lvim.get_context()
      close_float()
      stevearc.find_files({ cwd = ctx.dir, hidden = true })
    end
    local function open_tab()
      local ctx = lvim.get_context()
      close_float()
      vim.cmd("tabnew")
      vim.bo.buflisted = false
      vim.bo.bufhidden = "wipe"
      vim.cmd(string.format("tcd %s", ctx.dir))
    end
    local function livegrep()
      local ctx = lvim.get_context()
      close_float()
      require("telescope.builtin").live_grep({ cwd = ctx.dir })
    end
    local function subgrep()
      local ctx = lvim.get_context()
      close_float()
      vim.ui.input({ prompt = "grep " .. ctx.dir }, function(query)
        if query then
          vim.cmd(string.format("silent grep '%s' '%s'", query, ctx.dir))
        end
      end)
    end
    lir.setup({
      show_hidden_files = false,
      devicons_enable = vim.g.nerd_font,
      mappings = {
        ["<CR>"] = actions.edit,
        ["<C-s>"] = actions.split,
        ["<C-v>"] = actions.vsplit,
        ["<C-t>"] = open_tab,

        ["t"] = open_terminal,
        ["<leader>ff"] = find_files,
        ["<leader>fg"] = livegrep,
        ["gw"] = subgrep,

        ["-"] = actions.up,
        ["q"] = actions.quit,

        ["d"] = actions.mkdir,
        ["M"] = actions.mkdir,
        ["N"] = actions.newfile,
        ["%"] = actions.newfile,
        ["r"] = actions.rename,
        ["R"] = actions.rename,
        ["`"] = actions.cd,
        ["Y"] = actions.yank_path,
        ["."] = actions.toggle_show_hidden,
        ["D"] = actions.delete,

        ["J"] = function()
          mark_actions.toggle_mark()
          vim.cmd("normal! j")
        end,
        ["y"] = clipboard_actions.copy,
        ["x"] = clipboard_actions.cut,
        ["p"] = clipboard_actions.paste,
      },
      float = {
        winblend = 10,
        curdir_window = {
          enable = true,
          highlight_dirname = true,
        },

        win_opts = function()
          local total_height = vim.o.lines - vim.o.cmdheight
          local width = vim.o.columns - 6
          local height = total_height - 8
          local col = 2
          local row = 4
          return {
            relative = "editor",
            border = "rounded",
            width = width,
            height = height,
            row = row,
            col = col,
          }
        end,
      },
      hide_cursor = false,
    })
  end
)
vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "nvim-treesitter-context highlights",
  pattern = "*",
  command = "highlight link TreesitterContextLineNumber NormalFloat",
  group = aug,
})

if vim.g.nerd_font ~= false then
  safe_require("nvim-web-devicons").setup({
    default = true,
  })
end

vim.g.arduino_serial_cmd = "picocom {port} -b {baud} -l"

local function run_file(cmd)
  vim.cmd("update")
  local task = require("overseer").new_task({
    cmd = cmd,
    components = { "unique", "default" },
  })
  task:start()
  local bufnr = task:get_bufnr()
  if bufnr then
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, bufnr)
  end
end

-- Filetype mappings and options
ftplugin.setup({ augroup = aug })
ftplugin.set_all({
  arduino = {
    bindings = {
      { "n", "<leader>ac", ":wa<CR>:ArduinoVerify<CR>" },
      { "n", "<leader>au", ":wa<CR>:ArduinoUpload<CR>" },
      { "n", "<leader>ad", ":wa<CR>:ArduinoUploadAndSerial<CR>" },
      { "n", "<leader>ab", "<CMD>ArduinoChooseBoard<CR>" },
      { "n", "<leader>ap", "<CMD>ArduinoChooseProgrammer<CR>" },
    },
  },
  cs = {
    opt = {
      foldlevel = 0,
      foldmethod = "syntax",
    },
    bufvar = {
      match_words = "\\s*#\\s*region.*$:\\s*#\\s*endregion",
      all_folded = 1,
    },
  },
  defx = {
    opt = {
      bufhidden = "wipe",
    },
  },
  DressingInput = {
    bindings = {
      { "i", "<C-k>", '<CMD>lua require("dressing.input").history_prev()<CR>' },
      { "i", "<C-j>", '<CMD>lua require("dressing.input").history_next()<CR>' },
    },
  },
  fugitiveblame = {
    bindings = {
      { "n", "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  go = {
    opt = {
      list = false,
      listchars = "nbsp:⦸,extends:»,precedes:«,tab:  ",
    },
  },
  help = {
    bindings = {
      { "n", "gd", "<C-]>" },
    },
    opt = {
      list = false,
      textwidth = 80,
    },
  },
  lua = {
    abbr = {
      ["!="] = "~=",
      locla = "local",
      vll = "vim.log.levels",
    },
    bindings = {
      { "n", "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
    },
    opt = {
      comments = ":---,:--",
    },
  },
  make = {
    opt = {
      expandtab = false,
    },
  },
  markdown = {
    opt = {
      conceallevel = 2,
      formatoptions = "jqln",
    },
  },
  ["neotest-summary"] = {
    opt = {
      wrap = false,
    },
  },
  python = {
    abbr = {
      inn = "is not None",
      ipmort = "import",
      improt = "import",
    },
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
      textwidth = 88,
    },
    callback = function(bufnr)
      if vim.fn.executable("autoimport") == 1 then
        vim.keymap.set("n", "<leader>o", function()
          vim.cmd("write")
          vim.cmd("silent !autoimport " .. vim.api.nvim_buf_get_name(0))
          vim.cmd("edit")
          vim.lsp.buf.formatting({})
        end, { buffer = bufnr })
      end
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "python", vim.api.nvim_buf_get_name(0) })
      end, { buffer = bufnr })
    end,
  },
  qf = {
    opt = {
      winfixheight = true,
      relativenumber = false,
      buflisted = false,
    },
  },
  rust = {
    opt = {
      makeprg = "cargo $*",
    },
    callback = function(bufnr)
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "cargo", "run" })
      end, { buffer = bufnr })
    end,
  },
  sh = {
    callback = function(bufnr)
      -- Highlight variables inside strings
      vim.cmd([[
        hi link TSConstant Identifier
        hi link TSVariable Identifier
      ]])
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "bash", vim.api.nvim_buf_get_name(0) })
      end, { buffer = bufnr })
    end,
  },
  supercollider = {
    bindings = {
      { "n", "<CR>", "<Plug>(scnvim-send-block)", { remap = false } },
      { "i", "<c-CR>", "<Plug>(scnvim-send-block)", { remap = false } },
      { "x", "<CR>", "<Plug>(scnvim-send-selection)", { remap = false } },
      { "n", "<F1>", "<cmd>call scnvim#install()<CR><cmd>SCNvimStart<CR><cmd>SCNvimStatusLine<CR>" },
      { "n", "<F2>", "<cmd>SCNvimStop<CR>" },
      { "n", "<F12>", "<Plug>(scnvim-hard-stop)", { remap = false } },
      { "n", "<leader><space>", "<Plug>(scnvim-postwindow-toggle)", { remap = false } },
      { "n", "<leader>g", "<cmd>call scnvim#sclang#send('s.plotTree;')<CR>" },
      { "n", "<leader>s", "<cmd>call scnvim#sclang#send('s.scope;')<CR>" },
      { "n", "<leader>f", "<cmd>call scnvim#sclang#send('FreqScope.new;')<CR>" },
      { "n", "<leader>r", "<cmd>SCNvimRecompile<CR>" },
      { "n", "<leader>m", "<cmd>call scnvim#sclang#send('Master.gui;')<CR>" },
    },
    opt = {
      foldmethod = "marker",
      foldmarker = "{{{,}}}",
      statusline = "%f %h%w%m%r %{scnvim#statusline#server_status()} %= %(%l,%c%V %= %P%)",
    },
    callback = function(bufnr)
      vim.api.nvim_create_autocmd("WinEnter", {
        pattern = "*",
        command = "if winnr('$') == 1 && getbufvar(winbufnr(winnr()), '&filetype') == 'scnvim'|q|endif",
        group = "ClosePostWindowIfLast",
      })
    end,
  },
  vim = {
    opt = {
      foldmethod = "marker",
      keywordprg = ":help",
    },
  },
  zig = {
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
    },
  },
})

local function path_glob_to_regex(glob)
  local pattern = string.gsub(glob, "%.", "[%./]")
  pattern = string.gsub(pattern, "*", ".*")
  return "^" .. pattern .. "$"
end
local function reload(module)
  local pat = path_glob_to_regex(module)
  local mods = {}
  for k in pairs(package.loaded) do
    if string.match(k, pat) then
      table.insert(mods, k)
    end
  end
  for _, name in ipairs(mods) do
    package.loaded[k] = nil
  end
  for _, name in ipairs(mods) do
    require(k)
  end
  vim.notify(string.format("Reloaded %d modules", vim.tbl_count(mods)))
end
vim.api.nvim_create_user_command("Reload", function(params)
  local module = params.fargs[1]
  if module == "" then
    module = nil
  end
  if module then
    reload(module)
  else
    vim.ui.input({ prompt = "reload module" }, function(name)
      if name then
        reload(name)
      end
    end)
  end
end, { nargs = "?" })

-- vim-matchup
vim.g.matchup_surround_enabled = 1
vim.g.matchup_matchparen_nomode = "i"
vim.g.matchup_matchparen_deferred = 1
vim.g.matchup_matchparen_deferred_show_delay = 400
vim.g.matchup_matchparen_deferred_hide_delay = 400
vim.g.matchup_matchparen_offscreen = {}
vim.keymap.set({ "n", "x" }, "[[", "<plug>(matchup-[%)")
vim.keymap.set({ "n", "x" }, "]]", "<plug>(matchup-]%)")

-- :W and :H to set win width/height
vim.api.nvim_create_user_command("W", function(params)
  local width = tonumber(params.fargs[1])
  if math.floor(width) ~= width then
    width = math.floor(width * vim.o.columns)
  end
  vim.api.nvim_win_set_width(0, width)
end, { nargs = 1 })
vim.api.nvim_create_user_command("H", function(params)
  local height = tonumber(params.fargs[1])
  if math.floor(height) ~= height then
    height = math.floor(height * vim.o.lines - vim.o.cmdheight)
  end
  vim.api.nvim_win_set_height(0, height)
end, { nargs = 1 })

-- Generate helptags after startup
vim.defer_fn(function()
  if not vim.bo.filetype:match("^git") then
    vim.cmd("helptags ALL")
  end
end, 1000)
