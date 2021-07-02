if g:use_barbar
  function! s:CloseBufferOrWin() abort
    " if we're in a non-normal or floating window: close
    if win_gettype() != '' || s:IsFloatingWin(winnr())
      close
      return
    endif

    let i = 1
    let num_normal_wins = 0
    let in_normal_window = v:false
    while i <= winnr('$')
      if s:IsNormalWin(i)
        let num_normal_wins += 1
        if i == winnr()
          let in_normal_window = v:true
        endif
      endif
      let i += 1
    endwhile

    if num_normal_wins > 1 || !in_normal_window
      close
    else
      BufferClose
    endif
  endfunction

  function! s:IsFloatingWin(winnr) abort
    return nvim_win_get_config(win_getid(a:winnr)).relative != ''
  endfunction

  function! s:IsNormalWin(winnr) abort
    " Check for non-normal (e.g. popup/preview) windows
    if !empty(win_gettype(a:winnr)) || s:IsFloatingWin(a:winnr)
      return v:false
    endif
    let bufnr = winbufnr(a:winnr)
    let ft = getbufvar(bufnr, '&filetype')
    let bt = getbufvar(bufnr, '&buftype')

    " Ignore quickfix, prompt, help, and aerial buffer windows
    return bt != 'quickfix' && bt != 'prompt' && bt != 'help' && ft != 'aerial'
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
  nnoremap <silent> <leader>c <cmd>call <sid>CloseBufferOrWin()<CR>
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
