local is_mac = vim.uv.os_uname().sysname == "Darwin"
local node = vim.uv.os_homedir() .. "/.nodenv/versions/23.11.0/bin/node"

return {
  { "stevearc/stickybuf.nvim", cmd = { "PinBuffer", "PinBuftype", "PinFiletype" }, opts = {} },
  { "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
  "wellle/targets.vim",
  {
    "stevearc/vim-arduino",
    ft = "arduino",
    init = function() vim.g.arduino_serial_cmd = "picocom {port} -b {baud} -l" end,
  },
  { "tpope/vim-eunuch", ft = { "sh" }, cmd = { "Remove", "Delete" } },
  "tpope/vim-repeat",
  { "tpope/vim-endwise", event = "InsertEnter" },
  "tpope/vim-surround",
  {
    "tpope/vim-abolish",
    keys = {
      { "cr", "<Plug>(abolish-coerce-word)", mode = "n" },
    },
  },
  { "docunext/closetag.vim", event = "InsertEnter *" },
  {
    "stevearc/scnvim",
    ft = "supercollider",
    init = function()
      vim.g.scnvim_no_mappings = 1
      vim.g.scnvim_eval_flash_repeats = 1
    end,
  },
  { "Saecki/crates.nvim", cmd = "BufReadPre Cargo.toml", config = true },
  {
    "AckslD/nvim-FeMaco.lua",
    cmd = "FeMaco",
    config = true,
  },
  {
    "nvim-tree/nvim-web-devicons",
    cond = vim.g.nerd_font,
    opts = { default = true },
    lazy = true,
    config = true,
  },
  {
    "ojroques/nvim-osc52",
    -- Only change the clipboard if we're in a SSH session and using tmux (nvim 0.10 has osc52
    -- support built-in otherwise)
    cond = os.getenv("SSH_CLIENT") ~= nil and os.getenv("TMUX") ~= nil,
    config = function()
      local osc52 = require("osc52")
      local function copy(lines, _) osc52.copy(table.concat(lines, "\n")) end

      local function paste() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end

      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }
    end,
  },
  { "stevearc/openai.nvim", cmd = { "AIChat", "AIEdit" }, config = true },
  {
    "willothy/flatten.nvim",
    -- Disable when headless, because it causes neotest to hang
    -- https://github.com/willothy/flatten.nvim/issues/106
    cond = #vim.api.nvim_list_uis() > 0,
    opts = {
      window = {
        open = "tab",
      },
      one_per = { kitty = false, wezterm = false },
      block_for = {
        gitcommit = true,
        gitrebase = true,
      },
      hooks = {
        post_open = function(bufnr, winnr, ft, is_blocking)
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
  },
  {
    "zbirenbaum/copilot.lua",
    cond = is_mac and vim.fn.filereadable(node) == 1,
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
      copilot_node_command = vim.uv.os_homedir() .. "/.nodenv/versions/23.11.0/bin/node",
    },
  },
  {
    "ggandor/lightspeed.nvim",
    keys = {
      { "gs", "<Plug>Lightspeed_omni_s", desc = "Lightspeed search", mode = "" },
    },
    opts = {
      jump_to_unique_chars = false,
      safe_labels = {},
    },
    config = function(_, opts) require("lightspeed").setup(opts) end,
    init = function() vim.g.lightspeed_no_default_keymaps = true end,
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
  { "levouh/tint.nvim", opts = {} },
  {
    "folke/which-key.nvim",
    cmd = "WhichKey",
    opts = {
      plugins = {
        spelling = {
          enabled = false,
        },
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>b", group = "Buffers" },
        { "<leader>d", group = "Debugger" },
        { "<leader>f", group = "Fuzzy find" },
        { "<leader>g", group = "Git" },
        { "<leader>j", group = "Multicursor" },
        { "<leader>o", group = "Overseer" },
        { "<leader>s", group = "Sessions" },
        { "<leader>t", group = "Tests" },
      })
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    cmd = "RenderMarkdown",
    opts = {
      heading = {
        sign = false,
      },
      code = {
        sign = false,
      },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  },
}
