" Rebind ultisnips to something never used. We use CleverTab :)
let g:UltiSnipsExpandTrigger="<f12>"
let g:UltiSnipsJumpForwardTrigger="<f12>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" Put all my useful ultisnips globals in here
py import sys, os; sys.path.append(os.environ['HOME'] + '/.vim/UltiSnips/mods')

snoremap <Tab> <Esc>:call UltiSnips#ExpandSnippetOrJump()<cr>
