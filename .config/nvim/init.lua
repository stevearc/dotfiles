vim.loader.enable()
_G.stevearc = {}

-- Profiling
local should_profile = os.getenv("NVIM_PROFILE")
-- NVIM_PROFILE=mod:othermod nvim
-- NVIM_PROFILE=* nvim
-- NVIM_PROFILE=start:* nvim
-- NVIM_PROFILE_SAMPLE=0.3 NVIM_PROFILE=start:* nvim
-- NVIM_PROFILE=none nvim
if should_profile then
  vim.opt.runtimepath:append("~/dotfiles/vimplugins/profile.nvim")
  local profile = require("profile")
  profile.instrument_autocmds()
  local method = "instrument"
  if should_profile:lower():match("^start") then
    should_profile = should_profile:sub(7)
    method = "start"
  end
  local patterns = vim.split(should_profile, ":", { trimempty = true })
  if vim.tbl_isempty(patterns) then
    table.insert(patterns, "*")
  end
  local sample_rate = tonumber(os.getenv("NVIM_PROFILE_SAMPLE"))
  if sample_rate then
    profile.set_sample_rate(sample_rate)
  end

  if #patterns ~= 1 or patterns[1] ~= "none" then
    profile[method](unpack(patterns))
  end

  local function toggle_profile()
    if profile.is_recording() then
      profile.stop()
      vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
        if filename then
          profile.export(filename)
          vim.notify(string.format("Wrote %s", filename))
        end
      end)
    else
      profile.start(should_profile or "*")
    end
  end
  vim.keymap.set("n", "<f1>", toggle_profile, { desc = "Toggle profiling" })
end

local _jit_profiling = false
local function toggle_jit_profile()
  local outfile = vim.fn.stdpath("cache") .. "/jit.log"
  if _jit_profiling then
    _jit_profiling = false
    require("jit.p").stop()
    vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.txt" }, function(filename)
      if filename then
        vim.uv.fs_rename(outfile, filename)
        vim.notify(string.format("Wrote %s", filename))
      end
    end)
  else
    _jit_profiling = true
    -- See https://luajit.org/ext_profiler.html for flags
    require("jit.p").start("3Fpli1s", outfile)
    vim.notify("Started LuaJIT profiling")
  end
end
vim.keymap.set("n", "<f2>", toggle_jit_profile, { desc = "Toggle LuaJIT profiling" })

local uv = vim.uv or vim.loop
vim.g.python3_host_prog = os.getenv("HOME") .. "/.envs/py3/bin/python"
if not uv.fs_stat(vim.g.python3_host_prog) then
  -- Disable the python provider if the virtualenv isn't found
  vim.g.loaded_python3_provider = 0
end
local aug = vim.api.nvim_create_augroup("StevearcNewConfig", {})

vim.g.nerd_font = true

-- Space is leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.o.breakindent = true -- Preserve indent when wrapping
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.o.expandtab = true -- Turn tabs into spaces
vim.o.formatoptions = "rqnlj"
vim.o.gdefault = true -- Use 'g' flag by default with :s/foo/bar
vim.opt.diffopt = "filler,internal,closeoff,algorithm:histogram,context:5,linematch:60"
vim.o.exrc = true -- Load .nvim.lua files
vim.o.guifont = "UbuntuMono Nerd Font:h10"
vim.o.ignorecase = true
vim.o.jumpoptions = "stack"
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
vim.o.switchbuf = "uselast"
vim.o.synmaxcol = 300 -- Don't syntax highlight long lines
vim.o.tabstop = 2
vim.o.textwidth = 100 -- Line width of 100
vim.o.updatetime = 400 -- CursorHold time default is 4s. Way too long
vim.o.whichwrap = "h,l" -- allow cursor to wrap to next/prev line
vim.o.wrap = true
vim.o.linebreak = true
vim.opt.wildignore:append(
  "*.png,*.jpg,*.jpeg,*.gif,*.wav,*.aiff,*.dll,*.pdb,*.mdb,*.so,*.swp,*.zip,*.gz,*.bz2,*.meta,*.svg,*.cache,*/.git/*"
)
vim.o.wildmenu = true
vim.o.wildmode = "longest,list,full"
if vim.fn.has("nvim-0.11") == 1 then
  vim.o.winborder = "rounded"
  vim.o.messagesopt = "hit-enter,history:1000"
  vim.o.tabclose = "uselast"
end

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
-- vim.opt.showbreak = "↳ " -- DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)

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
    cconf = "python",
    frag = "glsl",
    norg = "norg",
    rbi = "ruby",
    sky = "starlark",
    ptl = "petal",
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
  command = "if &bt != 'quickfix' | setlocal nocursorline | endif",
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

local obs = false
local function set_scrolloff(winid)
  local scrolloff
  if obs then
    scrolloff = math.floor(math.max(10, vim.api.nvim_win_get_height(winid) / 10))
  else
    scrolloff = 1 + math.floor(vim.api.nvim_win_get_height(winid) / 2)
  end
  vim.api.nvim_set_option_value("scrolloff", scrolloff, { scope = "local", win = winid })
end
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinNew", "VimResized" }, {
  desc = "Always keep the cursor vertically centered",
  pattern = "*",
  callback = function()
    if not vim.b.overseer_task then
      set_scrolloff(0)
    end
  end,
  group = aug,
})

vim.api.nvim_create_user_command("ToggleObs", function()
  obs = not obs
  vim.o.relativenumber = not obs
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.wo[winid].relativenumber = not obs
      set_scrolloff(winid)
    end
  end
end, {
  desc = "Toggle settings that make me easier to follow while pairing",
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
  command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif",
  group = aug,
})

-- Close the scratch preview automatically
vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave" }, {
  desc = "Close the popup-menu automatically",
  pattern = "*",
  command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
  group = aug,
})

vim.api.nvim_create_autocmd("BufNew", {
  desc = "Edit files with :line at the end",
  pattern = "*",
  group = aug,
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    local root, line = bufname:match("^(.*):(%d+)$")
    if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
      vim.schedule(function()
        vim.cmd.edit({ args = { root } })
        pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end)
    end
  end,
})

-- BASH-style movement in insert mode
vim.keymap.set("i", "<C-a>", "<C-o>^")
vim.keymap.set("i", "<C-e>", "<C-o>$")

vim.keymap.set("n", "<C-]>", function() require("tags").goto_definition() end, { desc = "Goto tag" })

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
  local width_str = params.fargs[1]
  local width = tonumber(width_str)
  if not width then
    return
  end
  if width < 0 or width_str:sub(1, 1) == "+" then
    width = vim.api.nvim_win_get_width(0) + width
  end
  if math.floor(width) ~= width then
    width = math.floor(width * vim.o.columns)
  end
  vim.api.nvim_win_set_width(0, width)
end, { nargs = 1 })
vim.api.nvim_create_user_command("H", function(params)
  local height_str = params.fargs[1]
  local height = tonumber(height_str)
  if not height then
    return
  end
  if height < 0 or height_str:sub(1, 1) == "+" then
    height = vim.api.nvim_win_get_height(0) + height
  end
  if math.floor(height) ~= height then
    height = math.floor(height * vim.o.lines - vim.o.cmdheight)
  end
  vim.api.nvim_win_set_height(0, height)
end, { nargs = 1 })

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
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

_G.pending_notifications = {
  old_notify = vim.notify,
}
local newNotify = function(...) table.insert(_G.pending_notifications, vim.F.pack_len(...)) end
vim.notify = newNotify

vim.defer_fn(function()
  if vim.notify == newNotify then
    vim.notify = _G.pending_notifications.old_notify
  end
  for _, args in ipairs(_G.pending_notifications) do
    vim.notify(vim.F.unpack_len(args))
  end
  _G.pending_notifications = nil
end, 1000)

-- Add luarocks to rtp
local home = uv.os_homedir()
package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/5.1/?.lua;"

local specs = {
  { import = "plugins" },
}
local localpath = vim.fn.stdpath("data") .. "-local"
if uv.fs_stat(localpath) then
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
  vim.cmd.colorscheme("darkblue")
else
  local ok = pcall(vim.cmd.colorscheme, "duskfox")
  if not ok then
    vim.cmd.colorscheme("habamax")
  end
end
