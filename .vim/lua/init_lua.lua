local completion = require("completion")

require('telescope').setup{
  defaults = {
    winblend = 10,
  },
}

require('stevearc.lsp').setup()
require('stevearc.treesitter').setup()
require('qf_helper').setup({})

local function barbar_highlights()
  local config = require("tokyonight.config")
  local colors = require("tokyonight.colors").setup(config)
  local util = require("tokyonight.util")
  local barbar_theme = {
    Current = {
      base = { bg = colors.fg_gutter, fg = colors.fg },
      Index = { bg = colors.fg_gutter, fg = colors.blue1 },
      Mod = { bg = colors.fg_gutter, fg = colors.warning },
      Sign = { bg = colors.fg_gutter, fg = colors.blue1 },
      Target = { bg = colors.fg_gutter, fg = colors.red },
    },
    Visible = {
      base = { bg = colors.none, fg = colors.fg },
      Index = { bg = colors.none, fg = colors.blue1 },
      Mod = { bg = colors.none, fg = colors.warning },
      Sign = { bg = colors.none, fg = colors.blue1 },
      Target = { bg = colors.none, fg = colors.red },
    },
    Inactive = {
      base = { bg = colors.none, fg = colors.dark5 },
      Index = { bg = colors.none, fg = colors.dark5 },
      Mod = { bg = colors.none, fg = util.darken(colors.warning, 0.7) },
      Sign = { bg = colors.none, fg = colors.border_highlight },
      Target = { bg = colors.none, fg = colors.red },
    },
    Tabpages = {
      base = { bg = colors.none, fg = colors.none },
    },
    Tabpage = {
      Fill = { bg = colors.none, fg = colors.border_highlight },
    }
  }
  for mode,pieces in pairs(barbar_theme) do
    for piece,hl in pairs(pieces) do
      local group = string.format('Buffer%s%s', mode, piece == 'base' and '' or piece)
      util.highlight(group, hl)
    end
  end
end
vim.defer_fn(barbar_highlights, 1)

local arduino_status = function()
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
      "require'stevearc.treesitter'.debug_node()",
      "require'stevearc.lsp'.debug_aerial_fold()",
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

-- Completion
if vim.g.completion_plugin == 'completion-nvim' then
  vim.cmd[[autocmd BufEnter * lua require'completion'.on_attach()]]
  vim.g.completion_enable_snippet = 'vim-vsnip'
  vim.g.completion_confirm_key = ""
  vim.g.completion_matching_smart_case = 1
  vim.g.completion_matching_strategy_list = {'exact', 'fuzzy'}

  completion.addCompletionSource("glsl",
    {item = require'completion.source.glsl_keywords'.get_completion_items})

  vim.g.completion_chain_complete_list = {
    glsl = {
      {complete_items = {'glsl', 'buffers'}},
      {complete_items = {'snippet'}},
    },
    supercollider = {
      {complete_items = {'buffers'}},
      {complete_items = {'snippet'}},
    },
    default = {
      {complete_items = {'lsp'}},
      {complete_items = {'buffers'}},
      {complete_items = {'snippet'}},
    },
  }
  vim.g.completion_auto_change_source = 1
end

if vim.g.completion_plugin == 'compe' then
  require'compe'.setup {
    enabled = true;
    autocomplete = true;
    debug = false;
    documentation = true;
    min_length = 1;
    source = {
      buffer = true;
      vsnip = true;
      nvim_lsp = true;
      nvim_lua = true;
    };
  }
end
