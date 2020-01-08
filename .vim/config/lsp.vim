" Configuration for LanguageClient
let g:LanguageClient_autoStart = 1
let g:LanguageClient_diagnosticsList = 'Location'

let g:LanguageClient_serverCommands = {
\ 'javascript': ['flow', 'lsp', '--from', 'vim', '--lazy'],
\ 'javascript.jsx': ['flow', 'lsp', '--from', 'vim', '--lazy'],
\ 'php': ['hh', 'lsp', '--from', 'vim'],
\ 'python': ['pyls'],
\ 'rust': ['rustup', 'run', 'stable', 'rls'],
\ 'sh': ['bash-language-server', 'start'],
\ }
