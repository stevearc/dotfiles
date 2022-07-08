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
function stevearc.pack(...)
  return { n = select("#", ...), ... }
end

vim.g.python3_host_prog = os.getenv("HOME") .. "/.envs/py3/bin/python"
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local/site/pack/*/start/*")
local aug = vim.api.nvim_create_augroup("StevearcNewConfig", {})

local ftplugin = safe_require("ftplugin")
local opts = { noremap = true, silent = true }
vim.keymap.set({ "n", "i" }, "<f1>", toggle_profile)
vim.api.nvim_set_keymap(
  "n",
  "<f2>",
  [[<cmd>lua require'plenary.profile'.start("profile.log", {flame = true})<cr>]],
  opts
)
vim.api.nvim_set_keymap("n", "<f3>", [[<cmd>lua require'plenary.profile'.stop()<cr>]], opts)

vim.g.nerd_font = true
vim.g.debug_treesitter = false

-- Space is leader
vim.g.mapleader = " "

-- Options
vim.o.autoindent = true
vim.o.backspace = "indent,eol,start" -- Make backspace work properly
vim.o.backupcopy = "yes" -- Minimal downsides and doesn't break file watchers
vim.o.belloff = "all" -- Don't ring the bell
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.o.encoding = "utf-8" -- Set encoding to UTF
vim.o.expandtab = true -- Turn tabs into spaces
vim.o.fileformat = "unix" -- Set fileformat to Unix
vim.o.formatoptions = "rqnlj"
vim.o.gdefault = true -- Use 'g' flag by default with :s/foo/bar
vim.o.history = 1000 -- Remember 1000 commands and search history
vim.o.hlsearch = true -- Highlight search matches
vim.o.ignorecase = true
vim.o.incsearch = true -- Begin searching as soon as you start typing
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
vim.o.showcmd = true -- Display incomplete commands
vim.o.showmatch = true -- When a bracket is inserted, briefly jump to the matching one
vim.o.showtabline = 2 -- Always show tab line
vim.o.smartcase = true
vim.o.softtabstop = 2
vim.o.switchbuf = "useopen,uselast" -- Don't reopen buffers
vim.o.synmaxcol = 300 -- Don't syntax highlight long lines
vim.o.tabstop = 2
vim.o.textwidth = 80 -- Line width of 80
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
vim.api.nvim_set_keymap("c", "<C-a>", "<Home>", opts)
vim.api.nvim_set_keymap("c", "<C-b>", "<Left>", opts)
vim.api.nvim_set_keymap("c", "<C-f>", "<Right>", opts)
vim.api.nvim_set_keymap("c", "<C-d>", "<Delete>", opts)
vim.api.nvim_set_keymap("c", "<M-b>", "<S-Left>", opts)
vim.api.nvim_set_keymap("c", "<M-f>", "<S-Right>", opts)
vim.api.nvim_set_keymap("c", "<M-d>", "<S-right><Delete>", opts)
vim.api.nvim_set_keymap("c", "<Esc>b", "<S-Left>", opts)
vim.api.nvim_set_keymap("c", "<Esc>f", "<S-Right>", opts)
vim.api.nvim_set_keymap("c", "<Esc>d", "<S-right><Delete>", opts)
vim.api.nvim_set_keymap("c", "<C-g>", "<C-c>", opts)

-- Save jumps > 5 lines to the jumplist
-- Jumps <= 5 respect line wraps
vim.api.nvim_set_keymap("n", "j", [[(v:count > 5 ? "m'" . v:count . 'j' : 'gj')]], { noremap = true, expr = true })
vim.api.nvim_set_keymap("n", "k", [[(v:count > 5 ? "m'" . v:count . 'k' : 'gk')]], { noremap = true, expr = true })

-- Paste last text that was yanked, not deleted
vim.api.nvim_set_keymap("n", "<leader>p", '"0p', opts)
vim.api.nvim_set_keymap("n", "<leader>P", '"0P', opts)

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
}
vim.o.foldtext = [[v:lua.stevearc.foldtext()")]]

-- Use my universal clipboard tool to copy with <leader>y
vim.api.nvim_set_keymap("n", "<leader>y", '<cmd>call system("clip", @0)<CR>', opts)

-- Map leader-r to do a global replace of a word
vim.api.nvim_set_keymap("n", "<leader>r", [[*N:s//<C-R>=expand("<cword>")<CR>]], { noremap = true })

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
vim.api.nvim_set_keymap("i", "<C-v>", "<cmd>set paste<CR>", opts)
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
vim.api.nvim_set_keymap("i", "<C-a>", "<C-o>^", opts)
vim.api.nvim_set_keymap("i", "<C-e>", "<C-o>$", opts)

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
vim.env.INSIDE_NVIM = 1

-- For quick-n-dirty inspection
function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
  return ...
end

-- quickfix
vim.cmd([[
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])
]])
vim.api.nvim_set_keymap("n", "<C-N>", "<cmd>QNext<CR>", opts)
vim.api.nvim_set_keymap("n", "<C-P>", "<cmd>QPrev<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>q", "<cmd>QFToggle!<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>l", "<cmd>LLToggle!<CR>", opts)

local pending_notifications = {}
local old_notify = vim.notify
vim.notify = function(...)
  table.insert(pending_notifications, stevearc.pack(...))
end
-- We have to set this up after we apply our colorscheme
vim.cmd([[autocmd ColorScheme * ++once lua stevearc.setup_notify()]])
function stevearc.setup_notify()
  vim.notify = old_notify
  safe_require("notify", function(notify)
    vim.notify = notify
    notify.setup({
      stages = "fade",
      render = "minimal",
    })
  end)
  for _, args in ipairs(pending_notifications) do
    vim.notify(unpack(args))
  end
  pending_notifications = nil
end

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
    relative = "editor",
  },
})

vim.api.nvim_set_keymap("n", "<leader>n", "<cmd>GkeepToggle<CR>", { noremap = true })
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
  ftplugin.extend("aerial", { bindings = { "n", "<leader>a", "<CMD>AerialClose<CR>" } })
  aerial.setup({
    default_direction = "prefer_left",
    close_behavior = "global",
    highlight_on_jump = false,
    link_folds_to_tree = true,
    link_tree_to_folds = true,
    manage_folds = true,
    nerd_font = vim.g.nerd_font,
    max_width = { 80, 0.2 },

    -- backends = { "treesitter", "markdown" },
    -- backends = { "lsp", "markdown" },
    -- backends = { "lsp", "treesitter", "markdown" },
    -- filter_kind = false,
    on_attach = function(bufnr)
      vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
      vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>")
      vim.keymap.set("v", "{", "<cmd>AerialPrev<CR>")
      vim.keymap.set("n", "}", "<cmd>AerialNext<CR>")
      vim.keymap.set("v", "}", "<cmd>AerialNext<CR>")
    end,
  })
end)

vim.g.lightspeed_no_default_keymaps = true
safe_require("lightspeed", function(lightspeed)
  lightspeed.setup({
    jump_to_unique_chars = false,
    safe_labels = {},
  })
  -- Not sure which of these mappings I prefer yet
  vim.api.nvim_set_keymap("", "<leader>s", "<Plug>Lightspeed_omni_s", {})
  vim.api.nvim_set_keymap("", "gs", "<Plug>Lightspeed_omni_s", {})
end)
safe_require("tags", function(tags)
  tags.setup({
    on_attach = function(bufnr)
      vim.keymap.set("n", "gd", tags.goto_definition, { buffer = bufnr })
      vim.keymap.set("n", "<C-]>", tags.goto_definition, { buffer = bufnr })
    end,
  })
end)

-- Todo:
-- * Bug: Running tests on directory doesn't work if directory not in tree (but tree has subdirectories)
-- * Bug: No output or debug info if test fails to run (e.g. try running tests in cpython)
-- * Bug: Sometimes issues with running python tests (dir position stuck in running state)
-- * Bug: Files shouldn't appear in summary if they contain no tests (e.g. python file named 'test_*.py')
-- * Bug: default colors are not in-colorscheme
-- * Bug: dir/file/namespace status should be set by children
-- * Bug: Run last test doesn't work with marked tests (if ran all marked last)
-- * Feat: If summary tree only has a single (file/dir) child, merge the display
-- * Feat: Set default strategy (b/c can't set my strategy on the summary panel runs)
-- * Feat: Different bindings for expand/collapse
-- * Feat: Can collapse tree on a child node
-- * Feat: Can't rerun on save
-- * Feat: Can't rerun failed tests
-- * Feat: Populate test results as they come in
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
    neotest.setup({
      adapters = {
        python_adapter({
          dap = { justMyCode = false },
        }),
        plenary_adapter,
        jest_adapter,
      },
      discovery = {
        enabled = false,
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
        signs = false,
        virtual_text = true,
      },
    })
    vim.cmd([[
    hi! link NeotestPassed String
    hi! link NeotestFailed DiagnosticError
    hi! link NeotestRunning Constant
    hi! link NeotestSkipped DiagnosticInfo
    hi! link NeotestTest Normal
    hi! link NeotestNamespace TSKeyword
    hi! link NeotestMarked Bold
    hi! link NeotestFocused QuickFixLine
    hi! link NeotestFile Keyword
    hi! link NeotestDir Keyword
    hi! link NeotestIndent Conceal
    hi! link NeotestExpandMarker Conceal
    hi! link NeotestAdapterName TSConstructor
    ]])
    vim.keymap.set("n", "<leader>tn", function()
      neotest.run.run({ strategy = "overseer" })
    end)
    vim.keymap.set("n", "<leader>tt", function()
      neotest.run.run({ vim.api.nvim_buf_get_name(0), strategy = "overseer" })
    end)
    vim.keymap.set("n", "<leader>ta", function()
      for _, adapter_id in ipairs(neotest.run.adapters()) do
        neotest.run.run({ suite = true, adapter = adapter_id, strategy = "overseer" })
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
    component_aliases = {
      default = {
        "on_output_summarize",
        "result_exit_code",
        { "on_result_notify", desktop = "unfocused" },
        "on_restart_handler",
        "dispose_delay",
      },
    },
  })
  vim.api.nvim_create_user_command(
    "OverseerDebugParser",
    'lua require("overseer.parser.debug").start_debug_session()',
    {}
  )
  vim.keymap.set("n", "<leader>oo", "<cmd>OverseerToggle<CR>")
  vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>")
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

if vim.g.nerd_font ~= false then
  safe_require("nvim-web-devicons").setup({
    default = true,
  })
end

vim.g.arduino_serial_cmd = "picocom {port} -b {baud} -l"

local function run_file(cmd)
  vim.cmd([[
    write
    silent! clear
    botright split
  ]])
  vim.cmd(cmd)
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
      textwidth = 100,
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
  },
  lua = {
    abbr = {
      ["!="] = "~=",
      ["local"] = "local",
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
      if vim.fn.executable("autoimport") then
        vim.keymap.set("n", "<leader>o", function()
          vim.cmd("write")
          vim.cmd("silent !autoimport " .. vim.api.nvim_buf_get_name(0))
          vim.cmd("edit")
          vim.lsp.buf.formatting({})
        end, { buffer = bufnr })
      end
      vim.keymap.set("n", "<leader>e", function()
        run_file("terminal python %")
      end, { buffer = bufnr })
    end,
  },
  rust = {
    opt = {
      makeprg = "cargo $*",
    },
    callback = function(bufnr)
      vim.keymap.set("n", "<leader>e", function()
        run_file("terminal cargo run")
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
        run_file("terminal bash %")
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

-- vim-matchup
vim.g.matchup_surround_enabled = 1
vim.g.matchup_matchparen_nomode = "i"
vim.g.matchup_matchparen_deferred = 1
vim.g.matchup_matchparen_deferred_show_delay = 400
vim.g.matchup_matchparen_deferred_hide_delay = 400
vim.keymap.set({ "n", "x" }, "[", "<plug>(matchup-[%)")
vim.keymap.set({ "n", "x" }, "]", "<plug>(matchup-]%)")
