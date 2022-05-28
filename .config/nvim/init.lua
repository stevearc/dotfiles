_G.stevearc = {}

-- Profiling
local should_profile = os.getenv('NVIM_PROFILE')
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
    vim.ui.input({prompt = "Save profile to:", completion='file', default="profile.json"}, function(filename)
      if filename then
        prof.export(filename)
        vim.notify(string.format("Wrote %s", filename))
      end
    end)
  else
    prof.start("*")
  end
end
function _G.safe_require(name, cb)
  local ok, mod = pcall(require, name)
  if ok then
    if cb then
      cb(mod)
    end
    return mod
  else
    vim.notify(string.format("Missing module: %s", name), vim.log.levels.WARN)
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
function stevearc.pack(...)
  return { n = select("#", ...), ... }
end

vim.g.python3_host_prog = os.getenv("HOME") .. "/.envs/py3/bin/python"
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local/site/pack/*/start/*")
local aug = vim.api.nvim_create_augroup("StevearcNewConfig", {})

local opts = { noremap = true, silent = true }
vim.keymap.set({"n", "i"}, "<f1>", toggle_profile)
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
vim.opt.list = true -- show whitespace
vim.opt.listchars = {
  nbsp = "⦸", -- CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
  extends = "»", -- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
  precedes = "«", -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
  tab = "▷⋯", -- WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7) + MIDLINE HORIZONTAL ELLIPSIS (U+22EF, UTF-8: E2 8B AF)
}
vim.o.mouse = "a" -- Enable use of mouse
vim.o.number = true -- Except for current line
vim.o.path = "**" -- Use a recursive path (for :find)
vim.o.previewheight = 5
vim.o.pumblend = 10 -- Transparency for popup-menu
vim.o.relativenumber = true -- Relative line numbers
vim.o.ruler = true -- Show the row, column of the cursor
vim.o.shiftwidth = 2
vim.opt.shortmess:append("c") -- for nvim-cmp
vim.opt.shortmess:append("I") -- Hide the startup screen
vim.opt.shortmess:append("A") -- Ignore swap file messages
vim.opt.shortmess:append("a") -- Shorter message formats
vim.opt.showbreak = "↳ " -- DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)
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
safe_require("aerial", function(aerial)
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
    safe_labels = nil,
  })
  -- Not sure which of these mappings I prefer yet
  vim.api.nvim_set_keymap("", "<leader>s", "<Plug>Lightspeed_omni_s", {})
  vim.api.nvim_set_keymap("", "gs", "<Plug>Lightspeed_omni_s", {})
end)
safe_require("tags").setup({
  on_attach = function(bufnr)
    vim.keymap.set("n", "gd", tags.goto_definition, { buffer = bufnr })
    vim.keymap.set("n", "<C-]>", tags.goto_definition, { buffer = bufnr })
  end,
})
safe_require("overseer", function(overseer)
  overseer.setup()
  vim.keymap.set("n", "<leader>ot", function()
    overseer.run_template(
      { tags = { overseer.TAG.TEST }, prompt = "allow" },
      { filename = vim.api.nvim_buf_get_name(0) }
    )
  end)
  vim.keymap.set("n", "<leader>on", function()
    overseer.run_template(
      { tags = { overseer.TAG.TEST }, prompt = "allow" },
      { filename = vim.api.nvim_buf_get_name(0), line = vim.api.nvim_win_get_cursor(0)[1] }
    )
  end)
  vim.keymap.set("n", "<leader>oo", "<cmd>OverseerToggle<CR>")
  vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>")
  vim.keymap.set("n", "<leader>ol", "<cmd>OverseerLoadBundle<CR>")
  vim.keymap.set("n", "<leader>ob", "<cmd>OverseerBuild<CR>")
  vim.keymap.set("n", "<leader>oa", "<cmd>OverseerQuickAction 1<CR>")
  vim.keymap.set("n", "<leader>os", "<cmd>OverseerQuickAction<CR>")
end)
safe_require("hlslens", function(hlslens)
  hlslens.setup({
    calm_down = true,
    nearest_only = true,
  })

  local function map(lhs, rhs)
    vim.api.nvim_set_keymap("n", lhs, rhs, { noremap = true, silent = true })
  end
  map("n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]])
  map("N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]])

  -- Fix * and # behavior to respect smartcase
  map("*", [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]])
  map("#", [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]])
  map("g*", [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]])
  map("g#", [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]])
end)

if vim.g.nerd_font ~= false then
  safe_require("nvim-web-devicons").setup({
    default = true,
  })
end

-- vim-matchup
vim.g.matchup_surround_enabled = 1
vim.keymap.set({ "n", "x" }, "[", "<plug>(matchup-[%)")
vim.keymap.set({ "n", "x" }, "]", "<plug>(matchup-]%)")

-- vim-test
vim.g["test#preserve_screen"] = 1
vim.g["test#neovim#term_position"] = "vert"
vim.g["test#strategy"] = "neovim"
vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>TestFile<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>tn", "<cmd>TestNearest<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>ts", "<cmd>TestSuite<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>tl", "<cmd>TestLast<CR>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>tv", "<cmd>TestVisit<CR>", { silent = true })
