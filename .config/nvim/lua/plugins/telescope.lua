local lazy = require("lazy")
function stevearc.find_files(...)
  if stevearc._find_files_impl then
    stevearc._find_files_impl(...)
  else
    vim.notify("No fuzzy finder installed", vim.log.levels.ERROR)
  end
end
vim.keymap.set("n", "<leader>ff", function()
  stevearc.find_files()
end, { desc = "[F]ind [.]otfiles" })
lazy.require("telescope", function(telescope)
  telescope.setup({
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
  })
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

  stevearc._find_files_impl = function(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, {
      previewer = false,
    })
    require("telescope.builtin").find_files(opts)
  end
  vim.keymap.set("n", "<leader>f.", find_dotfiles, { desc = "[F]ind [.]otfiles" })
  vim.keymap.set("n", "<leader>fl", find_local_files, { desc = "[F]ind [L]ocal nvim files" })
  vim.keymap.set(
    "n",
    "<leader>bb",
    "<cmd>lua require('telescope.builtin').buffers({previewer=false, only_cwd=true})<cr>"
  )
  vim.keymap.set("n", "<leader>ba", "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>")
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "[F]ind by [G]rep" })
  vim.keymap.set("n", "<leader>fb", "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>")
  vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")
  vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commands<CR>")
  vim.keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<CR>")
  vim.keymap.set("n", "<leader>fs", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>")
  vim.keymap.set("n", "<leader>fq", "<cmd>Telescope quickfixhistory<CR>")
end)

if vim.fn.executable("fzf") == 1 then
  lazy.load("fzf-lua")
  lazy.require("fzf-lua", function(fzf)
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
  end)
end

lazy.multi("telescope.nvim", "aerial.nvim", {
  keymaps = { { "n", "<leader>fd", "<cmd>Telescope aerial<CR>", { desc = "[F]ind [D]ocument symbol" } } },
  post_config = function()
    pcall(lazy.require("telescope").load_extension, "aerial")
  end,
})
lazy.multi("telescope.nvim", "gkeep.nvim", {
  keymaps = { { "n", "<leader>fn", "<cmd>Telescope gkeep<CR>", { desc = "[F]ind [N]ote" } } },
  post_config = function()
    pcall(lazy.require("telescope").load_extension, "gkeep")
  end,
})
lazy.multi("telescope.nvim", "luasnip", {
  keymaps = {
    { "i", "<C-s>", "<cmd>lua require('telescope').extensions.luasnip.luasnip()<CR>", { desc = "[S]nippets" } },
  },
  post_config = function()
    pcall(lazy.require("telescope").load_extension, "luasnip")
  end,
})
