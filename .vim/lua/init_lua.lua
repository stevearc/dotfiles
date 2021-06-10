local completion = require("completion")

require('telescope').setup{
  defaults = {
    winblend = 10,
  },
}

require('stevearc.lsp').setup()
require('stevearc.treesitter').setup()

require('lualine').setup{
  options = {
    icons_enabled = vim.g.devicons ~= false,
    theme = 'solarized_dark',
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
      "require'stevearc.treesitter'.debug_node()"
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
