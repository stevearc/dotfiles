function stevearc.find_files(...)
  pcall(require, "telescope")
  pcall(require, "fzf-lua")
  if stevearc._find_files_impl then
    stevearc._find_files_impl(...)
  else
    vim.notify("No fuzzy finder installed", vim.log.levels.ERROR)
  end
end
vim.keymap.set("n", "<leader>ff", function() stevearc.find_files() end, { desc = "[F]ind [F]iles" })

vim.keymap.set("n", "<leader>fd", function()
  require("telescope").load_extension("aerial")
  vim.cmd("Telescope aerial")
end, { desc = "[F]ind [D]ocument symbol" })
vim.keymap.set("i", "<C-a>", function()
  require("telescope").load_extension("luasnip")
  require("telescope").extensions.luasnip.luasnip()
end, { desc = "[S]nippets" })

---@param path string
local function find_in_home(path)
  return function()
    stevearc.find_files({
      cwd = os.getenv("HOME") .. "/" .. path,
      follow = true,
      hidden = true,
      previewer = false,
    })
  end
end
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>f.", find_in_home(".config/nvim"), desc = "[F]ind [.]otfiles" },
      { "<leader>fn", find_in_home("Sync"), desc = "[F]ind [N]otes" },
      { "<leader>fl", find_in_home(".local/share/nvim-local"), desc = "[F]ind [L]ocal nvim files" },
      {
        "<leader>bb",
        "<cmd>lua require('telescope.builtin').buffers({previewer=false, only_cwd=true})<cr>",
        desc = "[B]uffer [B]uffet",
      },
      {
        "<leader>ba",
        "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>",
        desc = "[B]uffers [A]ll",
      },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "[F]ind by [G]rep" },
      {
        "<leader>fb",
        "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>",
        desc = "[F]ind in open [B]uffers",
      },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "[F]ind in [H]elp" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "[F]ind [C]ommand" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "[F]ind [K]eymap" },
      {
        "<leader>fw",
        "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>",
        desc = "[F]ind [W]orkspace symbol",
      },
      { "<leader>fq", "<cmd>Telescope quickfixhistory<CR>", desc = "[F]ind [Q]uickfix history" },
    },
    opts = {
      pickers = {
        colorscheme = {
          enable_preview = true,
        },
      },
      defaults = {
        winblend = 10,
        file_ignore_patterns = {
          ".*%.png$",
          ".*%.jpg$",
          ".*%.jpeg$",
          ".*%.gif$",
          ".*%.wav$",
          ".*%.aiff$",
          ".*%.dll$",
          ".*%.pdb$",
          ".*%.mdb$",
          ".*%.so$",
          ".*%.swp$",
          ".*%.zip$",
          ".*%.gz$",
          ".*%.bz2$",
          ".*%.meta",
          ".*%.cache",
          ".*/%.git/",
        },
      },
      extensions = {
        gkeep = {
          find_method = "title",
        },
        aerial = {
          show_nesting = {
            python = true,
          },
        },
      },
    },
    config = function(_, setup_opts)
      local telescope = require("telescope")
      telescope.setup(setup_opts)

      if not stevearc._find_files_impl then
        stevearc._find_files_impl = function(opts)
          opts = vim.tbl_deep_extend("keep", opts or {}, {
            previewer = false,
          })
          require("telescope.builtin").find_files(opts)
        end
      end
    end,
  },

  {
    "ibhagwan/fzf-lua",
    enabled = vim.fn.executable("fzf") == 1,
    lazy = true,
    keys = {
      { "<leader>fu", "<CMD>FzfLua blines<CR>", desc = "[F]ind b[u]ffer line" },
    },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        global_git_icons = false,
        files = {
          previewer = false,
        },
        git = {
          files = {
            previewer = false,
          },
        },
      })
      stevearc._find_files_impl = function(opts)
        opts = opts or {}
        -- git_files fails to find new files, which I often want
        -- if not opts.cwd and vim.fn.isdirectory(".git") == 1 then
        --   require("fzf-lua").git_files(opts)
        -- else
        require("fzf-lua").files(opts)
        -- end
      end
    end,
  },
}
