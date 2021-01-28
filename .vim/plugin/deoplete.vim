" Deoplete

let g:deoplete#enable_at_startup = g:completion_plugin == 'deoplete'
" Disable the candidates in Comment/String syntaxes.
call deoplete#custom#source('_', 'disabled_syntaxes', ['Comment', 'String'])
aug ClosePreview
    au!
    autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
aug END
call deoplete#custom#var('omni', 'input_patterns', {
    \ 'ruby': ['[^. *\t]\.\w*', '[a-zA-Z_]\w*::'],
    \ 'java': '[^. *\t]\.\w*',
    \ 'cs': '\w+|[^. *\t]\.\w*',
    \})
    " \ 'php': '\w+|[^. \t]->\w*|\w+::\w*',
" Allow a single colon into php keywords, but a double colon breaks it
call deoplete#custom#option('keyword_patterns', {
    \ 'php': '([\w-]+:)*[\w-]+',
    \})
call deoplete#custom#option('min_pattern_length', 1)
call deoplete#custom#option('sources', {
\ '_': ['lsp', 'ultisnips'],
\ 'hgcommit': ['tasks', 'ultisnips'],
\})


command! DeopleteDisable :call deoplete#disable()
command! DeopleteEnable :call deoplete#enable()
