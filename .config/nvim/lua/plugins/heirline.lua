return {
  "rebelot/heirline.nvim",
  enabled = true,
  dependencies = { "kyazdani42/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    local comp = require("heirline_components")
    local conditions = require("heirline.conditions")
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
        comp.rpad(comp.ArduinoStatus),
        comp.rpad(comp.SessionName),
        comp.rpad(comp.Overseer),
        comp.rpad(comp.FileType),
        comp.Ruler
      ),

      winbar = {
        fallthrough = false,
        { -- Hide the winbar for special buffers
          condition = function()
            return conditions.buffer_matches({
              buftype = { "nofile", "prompt", "quickfix", "terminal" },
              filetype = { "^git.*", "fugitive" },
            }) or vim.api.nvim_win_get_config(0).relative ~= ""
          end,
          init = function()
            vim.opt_local.winbar = nil
          end,
        },

        comp.FullFileName,
      },
    })
    -- Because heirline is lazy loaded, we need to manually set the winbar on startup
    vim.opt_local.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
  end,
}
