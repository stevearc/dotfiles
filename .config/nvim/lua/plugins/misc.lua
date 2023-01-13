return {
  "stevearc/stickybuf.nvim",
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
  "docunext/closetag.vim",
  "nanotee/luv-vimdocs",
  "editorconfig/editorconfig-vim",
  {
    "stevearc/scnvim",
    ft = "supercollider",
    init = function()
      vim.g.scnvim_no_mappings = 1
      vim.g.scnvim_eval_flash_repeats = 1
    end,
  },
  { "mfussenegger/nvim-jdtls", ft = "java" },
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
  {
    "klen/nvim-config-local",
    opts = { ".nvimrc.lua", ".vimrc.lua" },
  },
  { "kyazdani42/nvim-web-devicons", enabled = vim.g.nerd_font, opts = { default = true }, config = true },
  {
    "ojroques/nvim-osc52",
    -- Only change the clipboard if we're in a SSH session
    enabled = os.getenv("SSH_CLIENT"),
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
}
