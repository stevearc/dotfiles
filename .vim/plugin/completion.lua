if vim.g.completion_plugin == 'completion-nvim' then
  vim.cmd[[autocmd BufEnter * lua require'completion'.on_attach()]]
  vim.g.completion_enable_snippet = 'vim-vsnip'
  vim.g.completion_confirm_key = ""
  vim.g.completion_matching_smart_case = 1
  vim.g.completion_matching_strategy_list = {'exact', 'fuzzy'}

  require'completion'.addCompletionSource("glsl",
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


