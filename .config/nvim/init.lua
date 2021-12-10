-- Profiling
-- require('profile').instrument_autocmds()

local stevearc = require("stevearc")
vim.g.python3_host_prog = os.getenv("HOME") .. "/.envs/py3/bin/python"
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "-local")
local autocmds = { "augroup StevearcConfig", "au!" }

local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap(
  "n",
  "<f1>",
  [[<cmd>lua if require'profile'.is_recording() then require'profile'.stop('profile.json') else require'profile'.start('*') end<cr>]],
  opts
)
vim.api.nvim_set_keymap(
  "n",
  "<f2>",
  [[<cmd>lua require'plenary.profile'.start("profile.log", {flame = true})<cr>]],
  opts
)
vim.api.nvim_set_keymap("n", "<f3>", [[<cmd>lua require'plenary.profile'.stop()<cr>]], opts)

vim.g.nerd_font = true
vim.g.debug_treesitter = false

-- The syntax plugin was causing lag with multiple windows visible
vim.g.polyglot_disabled = { "sh" }

-- Minimal downsides and doesn't break file watchers
vim.o.backupcopy = "yes"

-- Space is leader
vim.g.mapleader = " "

-- Remember 1000 commands and search history
vim.o.history = 1000

-- Use a recursive path (for :find)
vim.o.path = "**"

-- When :find-ing, search for files with this suffix
vim.o.suffixesadd = ".py,.pyx,.java,.c,.cpp,.rb,.html,.jinja2,.js,.jsx,.less,.css,.styl,.ts,.tsx,.go,.rs"

-- Make tab completion for files/buffers act like bash
vim.o.wildmenu = true
vim.o.wildmode = "longest,list,full"
vim.opt.wildignore:append(
  "*.png,*.jpg,*.jpeg,*.gif,*.wav,*.aiff,*.dll,*.pdb,*.mdb,*.so,*.swp,*.zip,*.gz,*.bz2,*.meta,*.svg,*.cache,*/.git/*"
)

-- Make backspace work properly
vim.o.backspace = "indent,eol,start"

-- Make searches case-sensitive only if they contain upper-case characters
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.previewheight = 5

-- Show the row, column of the cursor
vim.o.ruler = true

-- Display incomplete commands
vim.o.showcmd = true

-- When a bracket is inserted, briefly jump to the matching one
vim.o.showmatch = true

-- Begin searching as soon as you start typing
vim.o.incsearch = true

-- Highlight search matches
vim.o.hlsearch = true

-- Highlight the cursor line only in the active window
table.insert(autocmds, "au VimEnter,WinEnter,BufWinEnter * setlocal cursorline")
table.insert(autocmds, "au WinLeave * setlocal nocursorline")

vim.o.formatoptions = "rqnlj"

-- Don't reopen buffers
vim.o.switchbuf = "useopen,uselast"

-- Always show tab line
vim.o.showtabline = 2

-- Size of tabs
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.autoindent = true
vim.o.laststatus = 2

-- Line width of 80
vim.o.textwidth = 80

-- CursorHold time default is 4s. Way too long
vim.o.updatetime = 100

-- Syntax highlighting
vim.cmd([[
syntax enable
syntax on
filetype plugin on
filetype plugin indent on
]])

-- Return to last edit position when opening files
table.insert(
  autocmds,
  [[
  autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") && expand('%:t') != 'COMMIT_EDITMSG' |
       \   exe "normal! g`\"" |
       \ endif
]]
)

-- Set fileformat to Unix
vim.o.fileformat = "unix"

-- Set encoding to UTF
vim.o.encoding = "utf-8"

-- Relative line numbers
vim.o.relativenumber = true
-- Except for current line
vim.o.number = true

-- Enable use of mouse
vim.o.mouse = "a"

-- Use 'g' flag by default with :s/foo/bar
vim.o.gdefault = true

-- allow cursor to wrap to next/prev line
vim.o.whichwrap = "h,l"

-- Set auto line wrapping options
vim.o.formatoptions = "rqnolj"

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

-- Move text in visual mode with J/K
vim.api.nvim_set_keymap("v", "J", [[:m '>+1<CR>gv=gv]], opts)
vim.api.nvim_set_keymap("v", "K", [[:m '<-2<CR>gv=gv]], opts)

-- Always keep cursor vertically centered
table.insert(autocmds, "au BufEnter,WinEnter,WinNew,VimResized *,*.* let &l:scrolloff=1+winheight(win_getid())/2")

vim.g.treesitter_languages = "maintained"
vim.g.treesitter_languages_blacklist = { "supercollider" }

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
vim.o.foldtext = [[luaeval("require('stevearc').foldtext()")]]

-- Use my universal clipboard tool to copy with <leader>y
vim.api.nvim_set_keymap("n", "<leader>y", '<cmd>call system("clip", @0)<CR>', opts)

-- Map leader-r to do a global replace of a word
vim.api.nvim_set_keymap("n", "<leader>r", [[*N:s//<C-R>=expand("<cword>")<CR>]], { noremap = true })

-- Expand %% to current directory in command mode
vim.cmd([[
cabbr <expr> %% expand('%:p:h')
]])

-- Reload files from disk when we focus vim
table.insert(autocmds, "au FocusGained * if getcmdwintype() == '' | checktime | endif")

-- Enter paste mode with <C-v> in insert mode
vim.api.nvim_set_keymap("i", "<C-v>", "<cmd>set paste<CR>", opts)
table.insert(autocmds, "au InsertLeave * set nopaste")

-- Close the scratch preview automatically
table.insert(
  autocmds,
  "autocmd CursorMovedI,InsertLeave * if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif"
)

-- BASH-style movement in insert mode
vim.api.nvim_set_keymap("i", "<C-a>", "<C-o>^", opts)
vim.api.nvim_set_keymap("i", "<C-e>", "<C-o>$", opts)

-- Super basic bracket completion
vim.api.nvim_set_keymap("i", "{<CR>", "{<CR>}<C-o>O", { noremap = true, nowait = true })
vim.api.nvim_set_keymap("i", "[<CR>", "[<CR>]<C-o>O", { noremap = true, nowait = true })
vim.api.nvim_set_keymap("i", "(<CR>", "(<CR>)<C-o>O", { noremap = true, nowait = true })

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

-- quickfix
vim.cmd([[
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])
]])
vim.api.nvim_set_keymap("n", "<C-N>", "<cmd>QNext<CR>", opts)
vim.api.nvim_set_keymap("n", "<C-P>", "<cmd>QPrev<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>q", "<cmd>QFToggle!<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>l", "<cmd>LLToggle!<CR>", opts)

require("qf_helper").setup({})
require("Comment").setup()
require("dressing").setup({
  input = {
    insert_only = false,
  },
})
vim.api.nvim_set_keymap("n", "<leader>n", "<cmd>GkeepToggle<CR>", { noremap = true })
-- vim.g.gkeep_sync_dir = '~/notes'
-- vim.g.gkeep_sync_archived = true
vim.g.gkeep_log_levels = {
  gkeep = "debug",
  gkeepapi = "warning",
}
vim.notify = require("notify")
require("notify").setup({
  stages = "fade",
  render = "minimal",
})

table.insert(autocmds, "augroup END")
vim.cmd(table.concat(autocmds, "\n"))
