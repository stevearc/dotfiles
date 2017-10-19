function! RunTests(filename)
    " Write the file and run tests for the given filename
    :w
    :silent !clear
    exec ":!nosetests " . a:filename
endfunction

function! SetTestFile()
    " Set the test file that tests will be run for.
    let t:test_file=@%
endfunction

function! RunTestFile(...)
    if a:0
        let command_suffix = a:1
    else
        let command_suffix = ""
    endif

    " Run the tests for the previously-marked file.
    let in_test_file = match(expand("%"), 'test_.*.py') != -1
    if in_test_file
        call SetTestFile()
    elseif !exists("t:test_file")
        return
    end
    call RunTests(t:test_file . command_suffix)
endfunction

" Run test file
noremap <buffer> <leader>dt :call RunTestFile()<CR>

" python-mode options
let g:pymode_run = 0
let g:pymode_lint = 0
let g:pymode_rope_organize_imports_bind = '<leader>o'
let g:pymode_rope_goto_definition_bind = 'gd'
let g:pymode_rope_goto_definition_cmd = 'e'
let g:pymode_rope_complete_on_dot = 0

" python-mode shortcuts
nnoremap <buffer> <leader>a :PymodeLintAuto<CR> zz

" Abbreviations
iabbr <buffer> inn is not None
iabbr <buffer> ipmort import
iabbr <buffer> improt import
