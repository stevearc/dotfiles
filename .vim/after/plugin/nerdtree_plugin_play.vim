if exists("g:loaded_nerdtree_plugin_play")
    finish
endif
let g:loaded_nerdtree_plugin_play = 1

function! s:script_name()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

function! s:play_callback(filenode)
    let cmd = "mplayer -really-quiet " . shellescape(a:filenode.path.str())
    call system(cmd)
endfunction

function! s:copy_callback(node)
    let @@ = a:node.path.str()
endfunction

call NERDTreeAddKeyMap({
    \ 'callback': s:script_name() . 'play_callback',
    \ 'quickhelpText': 'Play file',
    \ 'key': '<space>',
    \ 'scope': 'FileNode',
    \ })

call NERDTreeAddKeyMap({
    \ 'callback': s:script_name() . 'copy_callback',
    \ 'quickhelpText': 'Copy file path',
    \ 'key': 'y',
    \ 'scope': 'Node',
    \ })
