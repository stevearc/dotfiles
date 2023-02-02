_G.stevearc = {}
local p = require("p")

-- Profiling
local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  vim.opt.runtimepath:append("~/dotfiles/vimplugins/profile.nvim")
  require("profile").instrument_autocmds()
  if should_profile:lower():match("^start") then
    local pat = vim.split(should_profile, ":")[2] or "*"
    require("profile").start(pat)
  else
    require("profile").instrument(should_profile)
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
    prof.start(should_profile or "*")
  end
end
p.keymap("profile.nvim", "", "<f1>", toggle_profile, { desc = "Toggle profiling" })

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
if not vim.loop.fs_stat(vim.g.python3_host_prog) then
  -- Disable the python provider if the virtualenv isn't found
  vim.g.loaded_python3_provider = 0
end
local aug = vim.api.nvim_create_augroup("StevearcNewConfig", {})

vim.keymap.set("n", "<f2>", [[<cmd>lua require("plenary.profile").start("profile.log", {flame = true})<cr>]])
vim.keymap.set("n", "<f3>", [[<cmd>lua require("plenary.profile").stop()<cr>]])

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
vim.o.guifont = "UbuntuMono Nerd Font:h10"
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

if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
elseif vim.fn.executable("ag") == 1 then
  vim.o.grepprg = "ag --vimgrep"
  vim.o.grepformat = "%f:%l:%c:%m"
elseif vim.fn.executable("ack") == 1 then
  vim.o.grepprg = "ack --nogroup --nocolor"
elseif vim.fn.finddir(".git", ".;") ~= "" then
  vim.o.grepprg = "git --no-pager grep --no-color -n"
  vim.o.grepformat = "%f:%l:%m,%m %f match%ts,%f"
else
  vim.o.grepprg = "grep -nIR $* /dev/null"
end

local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
if is_tty then
  vim.o.termguicolors = false
else
  vim.o.termguicolors = true
end

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
vim.cmd.filetype({ args = { "plugin", "on" } })
vim.cmd.filetype({ args = { "plugin", "indent", "on" } })

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
  pattern = "*",
  command = 'let &l:scrolloff=1+winheight(win_getid())/2")',
  group = aug,
})

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
vim.o.foldtext = [[v:lua.stevearc.foldtext()")]]
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

-- Map leader-r to do a global replace of a word
vim.keymap.set("n", "<leader>r", [[*N:s//<C-R>=expand("<cword>")<CR>]])

-- Expand %% to current directory in command mode
vim.cmd.cabbr({ args = { "<expr>", "%%", "&filetype == 'oil' ? bufname('%')[6:] : expand('%:p:h')" } })

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

-- This lets our bash aliases know to use nvr instead of nvim
vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername

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
vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "nvim-treesitter-context highlights",
  pattern = "*",
  command = "highlight link TreesitterContextLineNumber NormalFloat",
  group = aug,
})

p.require("tags", function(tags)
  tags.setup({
    on_attach = function(bufnr)
      vim.keymap.set("n", "<C-]>", tags.goto_definition, { buffer = bufnr, desc = "Goto tag" })
    end,
  })
end)

-- Makes * and # work in visual mode
function stevearc.visual_set_search(cmdtype)
  local tmp = vim.fn.getreg("s")
  vim.cmd.normal({ args = { 'gv"sy' }, bang = true })
  vim.fn.setreg("/", "\\V" .. vim.fn.escape(vim.fn.getreg("s"), cmdtype .. "\\"):gsub("\n", "\\n"))
  vim.fn.setreg("s", tmp)
end
vim.keymap.set("x", "*", ':lua stevearc.visual_set_search("/")<CR>/<C-R>=@/<CR><CR>')
vim.keymap.set("x", "#", ':lua stevearc.visual_set_search("?")<CR>?<C-R>=@/<CR><CR>')

-- :W and :H to set win width/height
vim.api.nvim_create_user_command("W", function(params)
  local width = tonumber(params.fargs[1])
  if not width then
    return
  end
  if math.floor(width) ~= width then
    width = math.floor(width * vim.o.columns)
  end
  vim.api.nvim_win_set_width(0, width)
end, { nargs = 1 })
vim.api.nvim_create_user_command("H", function(params)
  local height = tonumber(params.fargs[1])
  if not height then
    return
  end
  if math.floor(height) ~= height then
    height = math.floor(height * vim.o.lines - vim.o.cmdheight)
  end
  vim.api.nvim_win_set_height(0, height)
end, { nargs = 1 })

-- Generate helptags after startup
vim.defer_fn(function()
  if not vim.bo.filetype:match("^git") then
    vim.cmd.helptags({ args = { "ALL" } })
  end
end, 1000)

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

local pending_notifications = {}
local old_notify = vim.notify
vim.notify = function(...)
  table.insert(pending_notifications, vim.F.pack_len(...))
end

local specs = {
  { import = "plugins" },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      -- We have to set this up after we apply our colorscheme
      vim.notify = old_notify
      local notify = require("notify")
      vim.notify = notify
      notify.setup({
        stages = "fade",
        render = "minimal",
        top_down = false,
      })
      for _, args in ipairs(pending_notifications) do
        vim.notify(vim.F.unpack_len(args))
      end
      pending_notifications = nil
    end,
  },
}
local localpath = vim.fn.stdpath("data") .. "-local"
if vim.loop.fs_stat(localpath) then
  table.insert(specs, { import = "local_plugins" })
end

require("lazy").setup({
  spec = specs,
  install = { colorscheme = { "duskfox", "habamax" } },
  dev = {
    path = "~/dotfiles/vimplugins",
    patterns = { "stevearc" },
  },
  checker = { enabled = false },
  change_detection = { enabled = false },
  performance = {
    rtp = {
      paths = {
        -- Add nvim-local to the runtimepath so we can extend the configuration
        localpath,
      },
      -- disable some rtp plugins
      disabled_plugins = {
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tohtml",
        "tutor",
      },
    },
  },
})

if is_tty then
  vim.cmd.colorscheme({ args = { "darkblue" } })
else
  vim.cmd.colorscheme({ args = { "duskfox" } })
end
