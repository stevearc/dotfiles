return {
  "rebelot/heirline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    local comp = require("heirline_components")
    local utils = require("heirline.utils")

    require("heirline").load_colors(comp.setup_colors())
    local aug = vim.api.nvim_create_augroup("Heirline", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      desc = "Update Heirline colors",
      group = aug,
      callback = function()
        local colors = comp.setup_colors()
        utils.on_colorscheme(colors)
      end,
    })

    require("heirline").setup({
      statusline = utils.insert(
        {
          static = comp.stl_static,
          hl = { bg = "bg" },
        },
        comp.ViMode,
        comp.lpad(comp.LSPActive),
        comp.lpad(comp.Diagnostics),
        require("statusline").left_components,
        { provider = "%=" },
        require("statusline").right_components,
        comp.rpad(comp.ConjoinStatus),
        comp.rpad(comp.ArduinoStatus),
        comp.rpad(comp.SessionName),
        comp.rpad(comp.Overseer),
        comp.rpad(comp.FileType),
        comp.Ruler
      ),

      winbar = {
        comp.FullFileName,
      },

      opts = {
        disable_winbar_cb = function(args)
          local buf = args.buf
          local ignore_buftype = vim.tbl_contains({ "prompt", "nofile", "terminal", "quickfix" }, vim.bo[buf].buftype)
          local filetype = vim.bo[buf].filetype
          local ignore_filetype = filetype == "fugitive" or filetype == "qf" or filetype:match("^git")
          local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
          return ignore_buftype or ignore_filetype or is_float
        end,
      },
    })

    vim.api.nvim_create_user_command("HeirlineResetStatusline", function()
      vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
    end, {})

    -- Because heirline is lazy loaded, we need to manually set the winbar on startup
    vim.opt_local.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
  end,
}
