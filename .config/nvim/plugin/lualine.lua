local function arduino_status()
  local ft = vim.api.nvim_buf_get_option(0, 'ft')
  if ft ~= 'arduino' then
    return ''
  end
  local port = vim.fn['arduino#GetPort']()
  local line = string.format('[%s]', vim.g.arduino_board)
  if vim.g.arduino_programmer ~= '' then
    line = line .. string.format(' [%s]', vim.g.arduino_programmer)
  end
  if port ~= 0 then
    line = line .. string.format(' (%s:)', port, vim.g.arduino_serial_baud)
  end
  return line
end

local function debug_aerial_fold()
  if vim.g.aerial_debug_fold then
    return require'aerial.fold'.foldexpr(vim.api.nvim_win_get_cursor(0)[1], true)
  else
    return ''
  end
end

local function debug_treesitter_node()
  local utils = require'nvim-treesitter.ts_utils'
  if vim.g.debug_treesitter and vim.g.debug_treesitter ~= 0 then
    return tostring(utils.get_node_at_cursor(0))
  else
    return ""
  end
end

require('lualine').setup{
  options = {
    icons_enabled = vim.g.devicons ~= false,
    -- theme = 'solarized_dark',
    theme = 'tokyonight',
    section_separators = "",
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {{
      'filename',
      file_status = true,
      path = 1,
    }},
    lualine_c = {{
        'diagnostics',
        sources = {'nvim_lsp'},
        sections = {'error', 'warn'},
      },
      debug_treesitter_node,
      debug_aerial_fold,
      arduino_status,
    },
    lualine_x = {'diff', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {{
      'filename',
      file_status = true,
      path = 1,
    }},
    lualine_c = {{'diagnostics',
      sources = {'nvim_lsp'},
      sections = {'error', 'warn'},
      colored = false,
    }},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  extensions = {'quickfix'}
}
