local lazy = require("lazy")
lazy.require(
  "lir",
  "lir.actions",
  "lir.mark.actions",
  "lir.clipboard.actions",
  function(lir, actions, mark_actions, clipboard_actions)
    vim.keymap.set("n", "-", function()
      require("lir.float").init()
    end)
    vim.keymap.set("n", "_", function()
      require("lir.float").init(".")
    end)
    local function close_float()
      if vim.api.nvim_win_get_config(0).relative ~= "" then
        vim.api.nvim_win_close(0, true)
      end
    end
    local lvim = require("lir.vim")
    local function open_terminal()
      local ctx = lvim.get_context()
      vim.cmd(string.format("lcd %s", ctx.dir))
      vim.cmd("terminal")
    end
    local function find_files()
      local ctx = lvim.get_context()
      close_float()
      stevearc.find_files({ cwd = ctx.dir, hidden = true })
    end
    local function open_tab()
      local ctx = lvim.get_context()
      close_float()
      vim.cmd("tabnew")
      vim.bo.buflisted = false
      vim.bo.bufhidden = "wipe"
      vim.cmd(string.format("tcd %s", ctx.dir))
    end
    local function livegrep()
      local ctx = lvim.get_context()
      close_float()
      require("telescope.builtin").live_grep({ cwd = ctx.dir })
    end
    local function subgrep()
      local ctx = lvim.get_context()
      close_float()
      vim.ui.input({ prompt = "grep " .. ctx.dir }, function(query)
        if query then
          vim.cmd(string.format("silent grep '%s' '%s'", query, ctx.dir))
        end
      end)
    end
    lir.setup({
      show_hidden_files = false,
      devicons_enable = vim.g.nerd_font,
      mappings = {
        ["<CR>"] = actions.edit,
        ["<C-s>"] = actions.split,
        ["<C-v>"] = actions.vsplit,
        ["<C-t>"] = open_tab,

        ["t"] = open_terminal,
        ["<leader>ff"] = find_files,
        ["<leader>fg"] = livegrep,
        ["gw"] = subgrep,

        ["-"] = actions.up,
        ["q"] = actions.quit,

        ["d"] = actions.mkdir,
        ["M"] = actions.mkdir,
        ["N"] = actions.newfile,
        ["%"] = actions.newfile,
        ["r"] = actions.rename,
        ["R"] = actions.rename,
        ["`"] = actions.cd,
        ["Y"] = actions.yank_path,
        ["."] = actions.toggle_show_hidden,
        ["D"] = actions.delete,

        ["J"] = function()
          mark_actions.toggle_mark()
          vim.cmd("normal! j")
        end,
        ["y"] = clipboard_actions.copy,
        ["x"] = clipboard_actions.cut,
        ["p"] = clipboard_actions.paste,
      },
      float = {
        winblend = 10,
        curdir_window = {
          enable = true,
          highlight_dirname = true,
        },

        win_opts = function()
          local total_height = vim.o.lines - vim.o.cmdheight
          local width = vim.o.columns - 6
          local height = total_height - 8
          local col = 2
          local row = 4
          return {
            relative = "editor",
            border = "rounded",
            width = width,
            height = height,
            row = row,
            col = col,
          }
        end,
      },
      hide_cursor = false,
    })
  end
)
