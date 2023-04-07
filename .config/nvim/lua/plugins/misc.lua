return {
  { "stevearc/stickybuf.nvim", config = true },
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
  "tpope/vim-eunuch",
  "tpope/vim-repeat",
  "tpope/vim-endwise",
  "tpope/vim-surround",
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
  { "numToStr/Comment.nvim", config = true },
  { "kyazdani42/nvim-web-devicons", enabled = vim.g.nerd_font, opts = { default = true }, lazy = true, config = true },
  {
    "ojroques/nvim-osc52",
    -- Only change the clipboard if we're in a SSH session
    enabled = os.getenv("SSH_CLIENT") ~= nil,
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
  {
    "jackMort/ChatGPT.nvim",
    enabled = vim.env.OPENAI_API_KEY ~= nil,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = {
      "ChatGPT",
      "ChatGPTActAs",
      "ChatGPTEditWithInstructions",
    },
    opts = { welcome_message = "", chat_input = {
      prompt = "",
    } },
  },
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
      end,
    },
  },
}
