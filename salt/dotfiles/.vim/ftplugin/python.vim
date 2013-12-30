" FIXME: This was causing errors somehow
" Run the code checker when entering a new buffer
"au BufReadPost *.py :silent PyLint

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
map <leader>dt :call RunTestFile()<CR>

" python-mode options
let g:pymode_lint_checker = "pylint"
" FIXME: This was causing errors because pylint checks aren't threadsafe
" let g:pymode_lint_onfly = 1
let g:pymode_lint_cwindow = 0
let g:pymode_run = 0
let ropevim_extended_complete=1

" python-mode shortcuts
map <leader>R :call RopeRename()<CR>
map <leader>o :call RopeOrganizeImports()<CR>
map <leader>g :call RopeFindOccurrences()<CR>
map <leader>d :call RopeShowDoc()<CR>
map <leader>a :PyLintAuto<CR>
map gd :call RopeGotoDefinition()<CR>

" Abbreviations
iabbr inn is not None
iabbr ipmort import
