local uv = vim.uv or vim.loop
local is_mac = uv.os_uname().sysname == "Darwin"
return {
  { "stevearc/stickybuf.nvim", cmd = { "PinBuffer", "PinBuftype", "PinFiletype" }, opts = {} },
  { "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
  { "godlygeek/tabular", cmd = { "Tabularize" } },
  "wellle/targets.vim",
  {
    "stevearc/vim-arduino",
    ft = "arduino",
    init = function()
      vim.g.arduino_serial_cmd = "picocom {port} -b {baud} -l"
    end,
  },
  "gioele/vim-autoswap",
  { "tpope/vim-eunuch", ft = { "sh" }, cmd = { "Remove", "Delete" } },
  "tpope/vim-repeat",
  { "tpope/vim-endwise", event = "InsertEnter" },
  "tpope/vim-surround",
  { "tpope/vim-abolish", keys = {
    { "cr", "<Plug>(abolish-coerce-word)", mode = "n" },
  } },
  { "docunext/closetag.vim", event = "InsertEnter *" },
  "nanotee/luv-vimdocs",
  {
    "stevearc/scnvim",
    ft = "supercollider",
    init = function()
      vim.g.scnvim_no_mappings = 1
      vim.g.scnvim_eval_flash_repeats = 1
    end,
  },
  { "dstein64/vim-startuptime", cmd = "StartupTime" },
  { "Saecki/crates.nvim", cmd = "BufReadPre Cargo.toml", config = true },
  "milisims/nvim-luaref",
  {
    "AckslD/nvim-FeMaco.lua",
    cmd = "FeMaco",
    config = true,
  },
  {
    "stevearc/pair-ls.nvim",
    cmd = { "Pair", "PairConnect" },
    config = true,
    opts = {
      cmd = { "pair-ls", "lsp" },
      -- cmd = { "pair-ls", "lsp", "-port", "8080" },
      -- cmd = { "pair-ls", "lsp", "-port", "8081" },
      -- cmd = { "pair-ls", "lsp", "-signal", "wss://localhost:8080" },
      -- cmd = { "pair-ls", "lsp", "-forward", "wss://localhost:8080" },
    },
  },
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gc", mode = { "n", "x" } },
      { "gcc", mode = "n" },
    },
    config = true,
  },
  { "nvim-tree/nvim-web-devicons", cond = vim.g.nerd_font, opts = { default = true }, lazy = true, config = true },
  {
    "ojroques/nvim-osc52",
    -- Only change the clipboard if we're in a SSH session
    cond = os.getenv("SSH_CLIENT") ~= nil,
    config = function()
      local osc52 = require("osc52")
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
    end,
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      window = {
        options = {
          relativenumber = false,
          number = false,
        },
      },
      plugins = {
        alacritty = {
          enabled = true,
          font = "24",
        },
      },
    },
  },
  { "stevearc/openai.nvim", cmd = { "AIChat", "AIEdit" }, config = true },
  {
    "willothy/flatten.nvim",
    opts = {
      window = {
        open = "tab",
      },
      block_for = {
        gitcommit = true,
        gitrebase = true,
      },
      post_open = function(bufnr, winnr, ft, is_blocking)
        vim.w[winnr].is_remote = true
        if is_blocking then
          vim.bo.bufhidden = "wipe"
          vim.api.nvim_create_autocmd("BufHidden", {
            desc = "Close window when buffer is hidden",
            callback = function()
              if vim.api.nvim_win_is_valid(winnr) then
                vim.api.nvim_win_close(winnr, true)
              end
            end,
            buffer = bufnr,
            once = true,
          })
        end
      end,
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<C-y>",
          accept_word = false,
          accept_line = false,
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-e>",
        },
      },
      panel = {
        enabled = false,
      },
    },
  },
  {
    "3rd/image.nvim",
    build = function()
      local has_magick = pcall(require, "magick")
      if not has_magick and vim.fn.executable("luarocks") == 1 then
        if is_mac then
          vim.fn.system("luarocks --lua-dir=$(brew --prefix)/opt/lua@5.1 --lua-version=5.1 install magick")
        else
          vim.fn.system("luarocks --local --lua-version=5.1 install magick")
        end
        if vim.v.shell_error ~= 0 then
          vim.notify("Error installing magick with luarocks", vim.log.levels.WARN)
        end
      end
    end,
    opts = {},
  },
}
