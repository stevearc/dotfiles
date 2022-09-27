local function find_files()
  vim.notify("No fuzzy finder installed", vim.log.levels.ERROR)
end
function stevearc.find_files(...)
  find_files(...)
end
vim.keymap.set("n", "<leader>ff", stevearc.find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>f.", function()
  stevearc.find_files({
    cwd = string.format("%s/.config/nvim/", os.getenv("HOME")),
    follow = true,
    hidden = true,
    previewer = false,
  })
end, { desc = "[F]ind [.]otfiles" })
vim.keymap.set("n", "<leader>fl", function()
  stevearc.find_files({
    cwd = string.format("%s/.local/share/nvim-local/", os.getenv("HOME")),
    follow = true,
    hidden = true,
    previewer = false,
  })
end, { desc = "[F]ind [L]ocal nvim files" })

safe_require("telescope", function(telescope)
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
      aerial = {
        show_nesting = false,
      },
    },
  })
  pcall(telescope.load_extension, "aerial")
  pcall(telescope.load_extension, "gkeep")
  pcall(telescope.load_extension, "luasnip")

  find_files = function(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, {
      previewer = false,
    })
    require("telescope.builtin").find_files(opts)
  end
  vim.keymap.set(
    "n",
    "<leader>bb",
    "<cmd>lua require('telescope.builtin').buffers({previewer=false, only_cwd=true})<cr>"
  )
  vim.keymap.set("n", "<leader>ba", "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>")
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
  vim.keymap.set("n", "<leader>fb", "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>")
  vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")
  vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commands<CR>")
  vim.keymap.set("n", "<leader>fs", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>")
  vim.keymap.set("n", "<leader>fd", "<cmd>Telescope aerial<CR>")
  vim.keymap.set("n", "<leader>fn", "<cmd>Telescope gkeep<CR>")
  vim.keymap.set("n", "<leader>fq", function()
    require("qf_stack").qf.set_list()
  end)
  vim.keymap.set("i", "<C-s>", "<cmd>lua require('telescope').extensions.luasnip.luasnip()<CR>")
end)

if vim.fn.executable("fzf") == 1 then
  safe_require("fzf-lua", function(fzf)
    fzf.setup({
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
    find_files = function(opts)
      opts = opts or {}
      if not opts.cwd and vim.fn.isdirectory(".git") == 1 then
        require("fzf-lua").git_files(opts)
      else
        require("fzf-lua").files(opts)
      end
    end
  end)
end
