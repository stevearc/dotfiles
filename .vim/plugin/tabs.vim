if g:use_barbar
  function! s:CloseBufferOrPane() abort
    if &bufhidden == 'unload' || &bufhidden == 'delete' || &bufhidden == 'wipe'
      quit
      return
    endif
    " if we're in a non-normal or floating window: quit
    if win_gettype(0) != '' || nvim_win_get_config(0)['relative'] != ''
      quit
      return
    endif

    let i = 1
    let last_window = winnr('$')
    let count = 0
    let in_main_window = v:false
    while i <= last_window
      " Ignore non-normal (e.g. popup/preview) windows
      if empty(win_gettype(i)) && !getwinvar(i, 'treesitter_context')
        let bufnr = winbufnr(i)
        let ft = getbufvar(bufnr, '&filetype')
        let bt = getbufvar(bufnr, '&buftype')
        " Ignore prompt & quickfix buffer windows
        if bt != 'quickfix' && bt != 'prompt' && bt != 'help' && ft != 'aerial'
          let count += 1
          if i == winnr()
            let in_main_window = v:true
          endif
        endif
      endif
      let i += 1
    endwhile

    if count > 1 || !in_main_window
      quit
    else
      " Close other windows (e.g. treesitter-context floating window) so we don't get the 'only floating window would remain' error
      silent wincmd o
      BufferClose
    endif
  endfunction

  let bufferline = get(g:, 'bufferline', {})
  let bufferline.closable = v:false
  let bufferline.animation = v:false
  let bufferline.icons = 'numbers'

  nnoremap <silent> H <cmd>BufferPrevious<CR>
  nnoremap <silent> L <cmd>BufferNext<CR>
  nnoremap <silent> <C-H> <cmd>BufferMovePrevious<CR>
  nnoremap <silent> <C-L> <cmd>BufferMoveNext<CR>
  nnoremap <leader>bm :BufferMove 
  nnoremap <silent> <leader>bi <cmd>BufferPin<CR>
  nnoremap <silent> <leader>bo <cmd>BufferOrderByTime<CR>
  nnoremap <silent> <leader>1 <cmd>BufferGoto 1<CR>
  nnoremap <silent> <leader>2 <cmd>BufferGoto 2<CR>
  nnoremap <silent> <leader>3 <cmd>BufferGoto 3<CR>
  nnoremap <silent> <leader>4 <cmd>BufferGoto 4<CR>
  nnoremap <silent> <leader>5 <cmd>BufferGoto 5<CR>
  nnoremap <silent> <leader>6 <cmd>BufferGoto 6<CR>
  nnoremap <silent> <leader>7 <cmd>BufferGoto 7<CR>
  nnoremap <silent> <leader>8 <cmd>BufferGoto 8<CR>
  nnoremap <silent> <leader>9 <cmd>BufferGoto 9<CR>
  nnoremap <silent> <leader>` <cmd>BufferLast<CR>
  nnoremap <silent> <leader>c <cmd>call <sid>CloseBufferOrPane()<CR>
  nnoremap <silent> <leader>C <cmd>BufferClose<CR>
  nnoremap <C-w><C-b> <cmd>tab split<CR>
  nnoremap <A-h> gT
  nnoremap <A-l> gt
  nnoremap <A-c> <cmd>tabclose<CR>
else
  " Fast tab navigation
  nnoremap <leader>1 1gt
  nnoremap <leader>2 2gt
  nnoremap <leader>3 3gt
  nnoremap <leader>4 4gt
  nnoremap <leader>5 5gt
  nnoremap <leader>6 6gt
  nnoremap <leader>7 7gt
  nnoremap <leader>8 8gt
  nnoremap <leader>9 9gt
  nnoremap <leader>` <cmd>$tabnext<CR>

  " Navigate tabs with H and L
  " We can't rebind <Tab> because that's equivalent to <C-i> and we want to keep
  " the <C-i>/<C-o> navigation :/
  nnoremap L gt
  nnoremap H gT

  nnoremap <C-w><C-b> <cmd>tab split<CR>
  nnoremap <C-w><C-t> <cmd>$tabnew<CR>
  nnoremap <C-H> <cmd>tabm -<CR>
  nnoremap <C-L> <cmd>tabm +<CR>
endif
