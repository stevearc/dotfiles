function stevearc.find_files() vim.notify("No fuzzy finder installed", vim.log.levels.ERROR) end

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
    "ibhagwan/fzf-lua",
    enabled = vim.fn.executable("fzf") == 1,
    lazy = true,
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        defaults = {
          git_icons = false,
        },
        files = {
          previewer = false,
        },
        git = {
          files = {
            previewer = false,
          },
        },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
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
        aerial = {
          format_symbol = function(symbol_path, filetype)
            if filetype == "json" or filetype == "yaml" or filetype == "python" then
              return table.concat(symbol_path, " > ")
            else
              return symbol_path[#symbol_path]
            end
          end,
        },
      },
    },
  },

  {
    "snacks-aerial",
    virtual = true,
    dependencies = {
      "folke/snacks.nvim",
      "stevearc/aerial.nvim",
    },
    keys = {
      {
        "<leader>fd",
        function()
          require("aerial").snacks_picker({
            layout = {
              preset = "dropdown",
              preview = false,
            },
          })
        end,
        desc = "[F]ind [D]ocument symbol",
      },
    },
  },

  {
    "telescope-luasnip",
    virtual = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "L3MON4D3/LuaSnip",
    },
    keys = {
      {
        "<C-a>",
        "<CMD>lua require('telescope').extensions.luasnip.luasnip()<CR>",
        desc = "[A]ll snippets",
        mode = "i",
      },
    },
    config = function() require("telescope").load_extension("luasnip") end,
  },

  {
    "fuzzy-find",
    virtual = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "folke/snacks.nvim",
      "ibhagwan/fzf-lua",
    },
    keys = {
      { "<leader>ff", function() stevearc.find_files() end, desc = "[F]ind [F]iles" },
      { "<leader>f.", find_in_home(".config/nvim"), desc = "[F]ind [.]otfiles" },
      { "<leader>fn", find_in_home("Sync"), desc = "[F]ind [N]otes" },
      { "<leader>fl", find_in_home(".local/share/nvim-local"), desc = "[F]ind [L]ocal nvim files" },
    },
    config = function()
      local has_fzf, fzf = pcall(require, "fzf-lua")
      if has_fzf then
        stevearc.find_files = function(opts)
          opts = opts or {}
          -- git_files fails to find new files, which I often want
          -- if not opts.cwd and vim.fn.isdirectory(".git") == 1 then
          --   fzf.git_files(opts)
          -- else
          fzf.files(opts)
          -- end
        end
      elseif Snacks and Snacks.picker then
        stevearc.find_files = function(opts)
          opts = opts or {}
          if opts.cwd then
            opts.dirs = { opts.cwd }
          end
          opts.layout = {
            preview = false,
          }
          Snacks.picker.files(opts)
        end
      else
        stevearc.find_files = function(opts)
          opts = vim.tbl_deep_extend("keep", opts or {}, {
            previewer = false,
          })
          require("telescope.builtin").find_files(opts)
        end
      end
    end,
  },
}
