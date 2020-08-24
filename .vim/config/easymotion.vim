let s:numbermap = {
\ 'a': 1,
\ 's': 2,
\ 'd': 3,
\ 'f': 4,
\ 'g': 5,
\ 'h': 6,
\ 'j': 7,
\ 'k': 8,
\ 'l': 9,
\ ';': 0,
\}
function! RelativeJump(motion, mode) range
    if a:mode == 'x'
        " This is a hack to get the line numbers to display properly. As soon as
        " we call this function from visual mode, the cursor pops up to the top
        " of the visual selection. If that location is different, the relative
        " line numbers will be off. This will reselect the last visual
        " selection, exit that selection (putting the cursor at the correct
        " location), and then recenter the view.
        normal! gv
        exec "normal! " . visualmode()
        normal! zz
    endif
    setlocal relativenumber
    redraw!
    try
        let numInput = input('Jump to: ')
        let num = ''
        for char in split(numInput, '\zs')
            let num .= get(s:numbermap, char, char)
        endfor
        if a:mode == 'x'
            normal! gv
        endif
        normal! m'
        exec "normal! " . num . a:motion
        normal! zz^
    catch
        if a:mode == 'x'
            normal! gv
        endif
    endtry
    setlocal norelativenumber
endfunction

nnoremap <leader>j :call RelativeJump('j', 'n')<CR>
nnoremap <leader>k :call RelativeJump('k', 'n')<CR>
xnoremap <leader>j :call RelativeJump('j', 'x')<CR>
xnoremap <leader>k :call RelativeJump('k', 'x')<CR>
