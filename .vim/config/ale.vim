" Ale
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1

if executable('clang-tidy')
    let g:ale_cpp_clangtidy_executable = 'clang-tidy'
elseif executable('clang-tidy-6.0')
    let g:ale_cpp_clangtidy_executable = 'clang-tidy-6.0'
endif

let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_sign_style_error = "."
let g:ale_sign_style_warning = "."
let g:ale_set_highlights = 0
hi link ALEErrorSign    Error
hi link ALEWarningSign  Warning
hi link ALEStyleErrorSign    Error
hi link ALEStyleWarningSign  Warning
