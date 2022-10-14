local projects = require("projects")

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

local function lsp_messages()
  local ret = ""
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == "null-ls" then
      goto continue
    end
    for _, progress in pairs(client.messages.progress) do
      if not progress.done then
        ret = progress.title
        if progress.message then
          ret = ret .. " " .. progress.message
        end
        if progress.percentage then
          ret = string.format("%s %[%d%%]", ret, progress.percentage)
        end
        return ret
      end
    end
    ::continue::
  end
  return ret
end

local function session_name()
  return ""
end
safe_require("resession", function(resession)
  session_name = function()
    local session_name = resession.get_current()
    if not session_name then
      return ""
    end
    return string.format("session: %s", session_name)
  end
end)

-- Defer to allow colorscheme to be set
vim.defer_fn(function()
  safe_require("lualine").setup({
    options = {
      globalstatus = true,
      icons_enabled = vim.g.devicons ~= false,
      section_separators = "",
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
      },
      lualine_x = {
        lsp_messages,
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
    extensions = { "aerial", "fzf", "nvim-dap-ui", "quickfix", "overseer" },
  })
end, 10)
