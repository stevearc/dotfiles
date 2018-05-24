" Deoplete

let g:deoplete#enable_at_startup = 1
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
    \ 'php': '\w+|[^. \t]->\w*|\w+::\w*',
    \})
call deoplete#custom#option('min_pattern_length', 1)
call deoplete#custom#option('sources', {
\ '_': ['ultisnips'],
\ 'cs': ['omni', 'ultisnips'],
\ 'sh': ['LanguageClient', 'ultisnips'],
\ 'javascript': ['LanguageClient', 'ultisnips'],
\})
