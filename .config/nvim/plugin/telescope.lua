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

  local function map(lhs, rhs, mode)
    vim.api.nvim_set_keymap(mode or "n", lhs, rhs, { noremap = true, silent = true })
  end

  find_files = function(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, {
      previewer = false,
    })
    require("telescope.builtin").find_files(opts)
  end
  map("<leader>bb", "<cmd>lua require('telescope.builtin').buffers({previewer=false, only_cwd=true})<cr>")
  map("<leader>ba", "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>")
  map("<leader>fg", "<cmd>Telescope live_grep<CR>")
  map("<leader>fb", "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>")
  map("<leader>fh", "<cmd>Telescope help_tags<CR>")
  map("<leader>fp", "<cmd>lua stevearc.telescope_pick_project()<CR>")
  map("<leader>fc", "<cmd>Telescope commands<CR>")
  map("<leader>fs", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>")
  map("<leader>fd", "<cmd>Telescope aerial<CR>")
  map("<leader>fn", "<cmd>Telescope gkeep<CR>")
  map("<C-s>", "<cmd>lua require('telescope').extensions.luasnip.luasnip()<CR>", "i")
end)

if vim.fn.executable("fzf") == 1 then
  safe_require("fzf-lua", function(fzf)
    fzf.setup({
      files = {
        previewer = false,
      },
      -- This is required to support older version of fzf on remote devboxes
      fzf_opts = { ["--border"] = false },
      git = {
        files = {
          previewer = false,
        },
      },
    })
    find_files = function(opts)
      opts = opts or {}
      if not opts.cwd and vim.fn.finddir(".git", ".;") ~= "" then
        require("fzf-lua").git_files(opts)
      else
        require("fzf-lua").files(opts)
      end
    end
  end)
end
