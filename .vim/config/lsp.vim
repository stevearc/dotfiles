" Configuration for LSP
if luaeval('vim.lsp == null')
  finish
endif

let g:LanguageClient_autoStart = 0
" lua vim.lsp.set_log_level('trace')

highlight link LspDiagnosticsError ALEVirtualTextError
highlight link LspDiagnosticsErrorSign ALEErrorSign
highlight link LspDiagnosticsWarning ALEVirtualTextWarning
highlight link LspDiagnosticsWarningSign ALEWarningSign
highlight link LspDiagnosticsInformation ALEVirtualTextInfo
highlight link LspDiagnosticsInformationSign ALEInfoSign
highlight link LspDiagnosticsHint ALEVirtualTextInfo
highlight link LspDiagnosticsHintSign ALEInfoSign

" solarized8 doesn't support ALEVirtualText
highlight link ALEVirtualTextError ALEError
highlight link ALEVirtualTextWarning ALEWarning
highlight link ALEVirtualTextInfo ALEInfo

sign define LspDiagnosticsErrorSign text=• numhl=ALEErrorSignLineNr
sign define LspDiagnosticsWarningSign text=• numhl=ALEWarningSignLineNr
sign define LspDiagnosticsInformationSign text=. numhl=ALEInfoSignLineNr
sign define LspDiagnosticsHintSign text=. numhl=ALEInfoSignLineNr


lua << END
  local util = require 'nvim_lsp/util'

  require'nvim_lsp'.bashls.setup{}
  require'nvim_lsp'.gdscript.setup{}
  -- require'nvim_lsp'.omnisharp.setup{}
  require'nvim_lsp'.clangd.setup{}
  require'nvim_lsp'.html.setup{}
  require'nvim_lsp'.jsonls.setup{}
  require'nvim_lsp'.pyls.setup{
    settings = {
      pyls = {
        plugins = {
          mccabe = {
            enabled = false;
          };
          pycodestyle = {
            enabled = false;
          };
          yapf = {
            enabled = false;
          };
        }
      }
    }
  }
  require'nvim_lsp'.rust_analyzer.setup{}
  require'nvim_lsp'.tsserver.setup{
    filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
    root_dir = util.root_pattern("tsconfig.json", ".git");
  }
  require'nvim_lsp'.vimls.setup{}
  require'nvim_lsp'.yamlls.setup{}

  require'nvim_lsp'.flow.setup{
    cmd = {"flow", "lsp", "--lazy"};
    settings = {
      flow = {
        coverageSeverity = "warn";
        showUncovered = true;
        stopFlowOnExit = false;
        useBundledFlow = false;
      }
    }
  }
END
