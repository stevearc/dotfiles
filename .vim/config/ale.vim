" Ale
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1

if executable('clang-tidy')
    let g:ale_cpp_clangtidy_executable = 'clang-tidy'
elseif executable('clang-tidy-6.0')
    let g:ale_cpp_clangtidy_executable = 'clang-tidy-6.0'
endif
