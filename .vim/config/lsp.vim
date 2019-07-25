" Configuration for LanguageClient
let g:LanguageClient_autoStart = 1

let g:LanguageClient_serverCommands = {
\ 'sh': ['bash-language-server', 'start'],
\ 'php': ['hh', 'lsp', '--from', 'vim'],
\ 'javascript': ['flow', 'lsp', '--from', 'vim', '--lazy'],
\ 'javascript.jsx': ['flow', 'lsp', '--from', 'vim', '--lazy'],
\ }
