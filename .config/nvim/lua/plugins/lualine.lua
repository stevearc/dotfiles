return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "kyazdani42/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local function arduino_status()
      local ft = vim.api.nvim_buf_get_option(0, "ft")
      if ft ~= "arduino" then
        return ""
      end
      local port = vim.fn["arduino#GetPort"]()
      local line = string.format("[%s]", vim.g.arduino_board)
      if vim.g.arduino_programmer ~= "" then
        line = line .. string.format(" [%s]", vim.g.arduino_programmer)
      end
      if port ~= 0 then
        line = line .. string.format(" (%s:%s)", port, vim.g.arduino_serial_baud)
      end
      return line
    end

    local function session_name()
      local has_resession, resession = pcall(require, "resession")
      if has_resession then
        local current_session = resession.get_current()
        if current_session then
          return string.format("session: %s", current_session)
        end
      end
      return ""
    end

    lualine.setup({
      options = {
        globalstatus = true,
        icons_enabled = vim.g.devicons ~= false,
        section_separators = "",
        disabled_filetypes = {
          winbar = { "qf" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { {
          "filename",
          file_status = true,
          path = 1,
        } },
        lualine_c = {
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            sections = { "error", "warn" },
          },
          arduino_status,
          function()
            return require("projects")[0].status_c()
          end,
        },
        lualine_x = {
          function()
            return require("projects")[0].status_x()
          end,
          session_name,
          "GkeepStatus",
          { "overseer", unique = true },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = { {
          "filename",
          file_status = true,
          path = 1,
        } },
        lualine_c = {
          { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" }, colored = false },
        },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      winbar = {
        lualine_a = {},
        lualine_b = { {
          "filename",
          file_status = true,
          path = 1,
        } },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },

      inactive_winbar = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { {
          "filename",
          file_status = true,
          path = 1,
        } },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      extensions = {
        "fzf",
        "nvim-dap-ui",
        "quickfix",
        {
          filetypes = vim.g.sidebar_filetypes,
          sections = { lualine_a = { "filetype" } },
          sections_inactive = { lualine_a = { "filetype" } },
          winbar = {},
          winbar_inactive = {},
        },
      },
    })
  end,
}
