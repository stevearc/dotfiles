return {
  { "stevearc/stickybuf.nvim", cmd = { "PinBuffer", "PinBuftype", "PinFiletype" }, opts = {} },
  { "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
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
        kitty = {
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
          vim.bo[bufnr].bufhidden = "wipe"
          local has_stickybuf, stickybuf = pcall(require, "stickybuf")
          if has_stickybuf then
            stickybuf.pin(winnr)
          end
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
          accept = "<C-f>",
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
    "ggandor/lightspeed.nvim",
    keys = {
      { "<leader>s", "<Plug>Lightspeed_omni_s", desc = "Lightspeed search", mode = "" },
      { "gs", "<Plug>Lightspeed_omni_s", desc = "Lightspeed search", mode = "" },
    },
    opts = {
      jump_to_unique_chars = false,
      safe_labels = {},
    },
    config = function(_, opts)
      require("lightspeed").setup(opts)
    end,
    init = function()
      vim.g.lightspeed_no_default_keymaps = true
    end,
  },
  {
    "andymass/vim-matchup",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "[[", "<plug>(matchup-[%)", mode = { "n", "x" } },
      { "]]", "<plug>(matchup-]%)", mode = { "n", "x" } },
    },
    init = function()
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_matchparen_nomode = "i"
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_deferred_show_delay = 400
      vim.g.matchup_matchparen_deferred_hide_delay = 400
      vim.g.matchup_matchparen_offscreen = {}
    end,
  },
}
