#!/bin/bash
export NVENV

_nvenv-list() {
  ls ~/.local/share/nvenv 2>/dev/null || echo "No nvenvs available"
  if [ -n "$NVENV" ]; then
    echo "Active: $NVENV"
  fi
}

_nvenv-deactivate() {
  export NVENV=
  unalias nvim 2>/dev/null
  alias vim='nvim'
}

_nvenv-activate() {
  local name="${1?Usage: nvenv activate <name>}"
  if [ ! -e "$HOME/.local/share/nvenv/$name" ]; then
    echo "No nvenv $name found"
    return
  fi
  unalias vim 2>/dev/null
  unalias nvim 2>/dev/null
  alias nvim='_nvenv-nvim'
  alias vim='_nvenv-nvim'
  export NVENV="$name"
}

_nvenv-create() {
  local name=${1?Usage: nvenv create <name> [<binary_name>]}
  local bin_name=${2-nvim}
  mkdir -p "$HOME/.local/share/nvenv/$name"
  echo "$bin_name" >"$HOME/.local/share/nvenv/$name/bin_name"
}

_nvenv-delete() {
  local name=${1?Usage: nvenv delete <name>}
  rm -rf "$HOME/.local/share/nvenv/$name"
}

_nvenv-kickstart() {
  local name="${1-$NVENV}"
  local bin_name=${2-nvim}
  if [ -z "$name" ]; then
    echo "Usage nvenv kickstart <name>"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$name/config/nvim"
  echo "$bin_name" >"$HOME/.local/share/nvenv/$name/bin_name"
  curl -sL https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua -o "$HOME/.local/share/nvenv/$name/config/nvim/init.lua"
  'nvim' "$HOME/.local/share/nvenv/$name/config/nvim/init.lua"
}

_nvenv-lazy() {
  local name="${1-$NVENV}"
  local bin_name=${2-nvim}
  if [ -z "$name" ]; then
    echo "Usage nvenv lazy <name>"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$name/config/nvim"
  echo "$bin_name" >"$HOME/.local/share/nvenv/$name/bin_name"
  cat >"$HOME/.local/share/nvenv/$name/config/nvim/init.lua" <<EOF
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.o.expandtab = true -- Turn tabs into spaces
vim.o.shiftwidth = 2
vim.opt.shortmess:append("c") -- for nvim-cmp
vim.opt.shortmess:append("I") -- Hide the startup screen
vim.opt.shortmess:append("A") -- Ignore swap file messages
vim.opt.shortmess:append("a") -- Shorter message formats
vim.o.softtabstop = 2
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.textwidth = 100 -- Line width of 100
vim.o.updatetime = 400 -- CursorHold time default is 4s. Way too long
vim.o.wildmenu = true
vim.o.wildmode = "longest,list,full"
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

-- install plugins
local plugins = {
  "folke/tokyonight.nvim",
  { "stevearc/aerial.nvim", config = true },
  { "stevearc/oil.nvim", config = function()
      local oil = require("oil")
      oil.setup()
      vim.keymap.set("n", "-", oil.open)
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua" },
        auto_install = true,
        highlight = { enable = true },
      })
    end,
  },
  -- add any other plugins here
}
require("lazy").setup(plugins, {
  dev = {
    path = "~/dotfiles/vimplugins",
    patterns = {"stevearc"}
  }
})

vim.cmd.colorscheme("tokyonight")
-- add anything else here
EOF
  'nvim' "$HOME/.local/share/nvenv/$name/config/nvim/init.lua"
}

_nvenv-repro() {
  local name="${1-repro.lua}"
  cat >"$name" <<EOF
-- save as repro.lua
-- run with nvim -u repro.lua
-- DO NOT change the paths
local root = vim.fn.fnamemodify("./.repro", ":p")

-- set stdpaths to use .repro
for _, name in ipairs({ "config", "data", "state", "runtime", "cache" }) do
  vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

-- bootstrap lazy
local lazypath = root .. "/plugins/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- install plugins
local plugins = {
  "folke/tokyonight.nvim",
  -- add any other plugins here
}
require("lazy").setup(plugins, {
  root = root .. "/plugins",
})

vim.cmd.colorscheme("tokyonight")
-- add anything else here
EOF
  'nvim' "$name"
}

_nvenv-cd() {
  local name="${1?Usage: nvenv cd <name>}"
  cd "$HOME/.local/share/nvenv/$name"
}

_nvenv-nvim() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/config"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/data"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/state"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/run"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/cache"
  local bin_name
  bin_name="$(cat "$HOME/.local/share/nvenv/$NVENV/bin_name")"
  XDG_CONFIG_HOME="$HOME/.local/share/nvenv/$NVENV/config" \
    XDG_DATA_HOME="$HOME/.local/share/nvenv/$NVENV/data" \
    XDG_STATE_HOME="$HOME/.local/share/nvenv/$NVENV/state" \
    XDG_RUNTIME_DIR="$HOME/.local/share/nvenv/$NVENV/run" \
    XDG_CACHE_HOME="$HOME/.local/share/nvenv/$NVENV/cache" \
    "$bin_name" "$@"
}

# Install a plugin
_nvenv-install() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  local repo="${1?Usage: nvenv install [REPO]}"
  local name="${1##*/}"
  git clone "$repo" "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$name/start/$name"
}

# Link a plugin from the default nvim install
_nvenv-link() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/"
  while [ -n "$1" ]; do
    rm -f "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$1"
    ln -s "$HOME/.local/share/nvim/site/pack/$1" "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$1"
    shift
  done
}

# Edit the init file for a nvenv
_nvenv-edit() {
  local name="${1-$NVENV}"
  if [ -z "$name" ]; then
    echo "Usage nvenv edit <name>"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$name/config/nvim"
  'nvim' "$HOME/.local/share/nvenv/$name/config/nvim/init.lua"
}

# Clone a nvenv
_nvenv-clone() {
  local source="${1?Usage: nvenv clone <source> <target>}"
  local dest="${2?Usage: nvenv clone <source> <target>}"
  local src_data
  local src_config
  local bin_name
  if [ "$source" = "default" ] || [ "$source" = "nvim" ]; then
    src_data="$HOME/.local/share/nvim"
    src_config="$HOME/.config/nvim"
    bin_name="nvim"
  else
    src_data="$HOME/.local/share/nvenv/$source/data/nvim"
    src_config="$HOME/.local/share/nvenv/$source/config/nvim"
    bin_name="$(cat "$HOME/.local/share/nvenv/$source/bin_name")"
  fi
  src_site="$src_data/site/pack"
  _nvenv-create "$dest" "$bin_name"
  mkdir -p "$HOME/.local/share/nvenv/$dest/data/nvim/site/pack"
  for plugpath in "$src_site"/*; do
    local plugin
    plugin="$(basename "$plugpath")"
    ln -s "$plugpath" "$HOME/.local/share/nvenv/$dest/data/nvim/site/pack/$plugin"
  done
  mkdir -p "$HOME/.local/share/nvenv/$dest/config/nvim"
  rsync -rLptgoD "$src_config" "$HOME/.local/share/nvenv/$dest/config/"
}

nvenv() {
  local usage="nvenv [create|delete|list|activate|deactivate|install|link|kickstart|lazy|repro|edit]"
  local cmd="$1"
  if [ -z "$cmd" ]; then
    echo "$usage"
    return
  fi
  shift
  "_nvenv-$cmd" "$@"
}
