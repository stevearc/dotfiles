function stevearc.find_files(...)
  if stevearc._find_files_impl then
    stevearc._find_files_impl(...)
  else
    vim.notify("No fuzzy finder installed", vim.log.levels.ERROR)
  end
end
vim.keymap.set("n", "<leader>ff", function()
  pcall(require, "telescope")
  pcall(require, "fzf-lua")
  stevearc.find_files()
end, { desc = "[F]ind [F]iles" })

vim.keymap.set("n", "<leader>fn", function()
  require("telescope").load_extension("gkeep")
  vim.cmd([[Telescope gkeep]])
end)
vim.keymap.set("n", "<leader>fd", function()
  require("telescope").load_extension("aerial")
  vim.cmd("Telescope aerial")
end, { desc = "[F]ind [D]ocument symbol" })
vim.keymap.set("i", "<C-s>", function()
  require("telescope").load_extension("luasnip")
  require("telescope").extensions.luasnip.luasnip()
end, { desc = "[S]nippets" })

local function find_dotfiles()
  stevearc.find_files({
    cwd = string.format("%s/.config/nvim/", os.getenv("HOME")),
    follow = true,
    hidden = true,
    previewer = false,
  })
end
local function find_local_files()
  stevearc.find_files({
    cwd = string.format("%s/.local/share/nvim-local/", os.getenv("HOME")),
    follow = true,
    hidden = true,
    previewer = false,
  })
end
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>f.", find_dotfiles, { desc = "[F]ind [.]otfiles" }, mode = "n" },
      { "<leader>fl", find_local_files, { desc = "[F]ind [L]ocal nvim files" }, mode = "n" },
      {
        "<leader>bb",
        "<cmd>lua require('telescope.builtin').buffers({previewer=false, only_cwd=true})<cr>",
        mode = "n",
      },
      { "<leader>ba", "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>", mode = "n" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "[F]ind by [G]rep" }, mode = "n" },
      { "<leader>fb", "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>", mode = "n" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", mode = "n" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", mode = "n" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", mode = "n" },
      { "<leader>fs", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>", mode = "n" },
      { "<leader>fq", "<cmd>Telescope quickfixhistory<CR>", mode = "n" },
    },
    opts = {
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
        aerial = {},
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
    commit = "c9230c337d33a1c5437f0029cbda87e522516982", -- After this we lose support for fzf < 0.25
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        global_git_icons = false,
        files = {
          previewer = false,
        },
        -- This is required to support older version of fzf
        fzf_opts = { ["--border"] = false },
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
