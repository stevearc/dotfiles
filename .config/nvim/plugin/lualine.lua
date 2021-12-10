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

local function debug_treesitter_node()
  local utils = require("nvim-treesitter.ts_utils")
  if vim.g.debug_treesitter and vim.g.debug_treesitter ~= 0 then
    return tostring(utils.get_node_at_cursor(0))
  else
    return ""
  end
end

local function lsp_messages()
  local ret = ""
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    for _, progress in pairs(client.messages.progress) do
      if not progress.done then
        ret = progress.title
        if progress.message then
          ret = ret .. " " .. progress.message
        end
        if progress.percentage then
          ret = string.format("%s [%d%%]", ret, progress.percentage)
        end
        return ret
      end
    end
  end
  return ret
end

require("lualine").setup({
  options = {
    icons_enabled = vim.g.devicons ~= false,
    theme = "tokyonight",
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
      debug_treesitter_node,
      arduino_status,
    },
    lualine_x = { "GkeepStatus", lsp_messages, "filetype" },
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
  extensions = { "quickfix" },
})
