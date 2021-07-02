" This is what determines which windows/buffers to make sticky.
function! s:ShouldMakeSticky()
  return &buftype != '' || win_gettype() != '' || nvim_win_get_config(0).relative != ''
endfunction

function! s:MakeStickyBuf()
  let l:sticky_buf = get(w:, 'sticky_buf')
  if s:ShouldMakeSticky()
    if l:sticky_buf == 0
      " For special windows, save the buffer number as a window variable
      let w:sticky_buf = bufnr()
      " We have to override bufhidden so that the buffer won't be
      " unloaded or deleted if we navigate away from it
      let b:prev_bufhidden = &bufhidden
      set bufhidden=hide
      return
    endif
  endif
  if l:sticky_buf && l:sticky_buf != bufnr()
    " If this was a sticky buffer window and the buffer no longer matches, restore it
    let l:winid = win_getid()
    let l:newbuf = bufnr()
    call win_execute(l:winid, 'noau buffer ' . l:sticky_buf)
    " Then open the new buffer in the appropriate location
    call timer_start(1, { tid -> s:OpenInBestWindow(l:newbuf) })
  endif
endfunction

function! s:OpenInBestWindow(bufnr) abort
  let l:winnr = 1
  " If a non-special window exists, open the buffer there
  while l:winnr <= winnr('$')
    let l:winid = win_getid(l:winnr)
    silent! let l:sticky_buf = nvim_win_get_var(l:winid, 'sticky_buf')
    if !l:sticky_buf
      exec l:winnr . 'wincmd w'
      exec 'buffer ' . a:bufnr
      return
    endif
    let l:winnr += 1
  endwhile
  " Otherwise, open the buffer in a vsplit from the first window
  call win_execute(win_getid(1), 'vertical rightbelow sbuffer ' . a:bufnr)
  2wincmd w
endfunction

function! s:RestoreBufHidden(winid) abort
  let l:bufnr = winbufnr(str2nr(a:winid))
  " If the buffer is still visible somewhere, we don't need to do anything
  if len(win_findbuf(l:bufnr)) > 1
    return
  endif
  silent! let l:prev_bufhidden = nvim_buf_get_var(l:bufnr, 'prev_bufhidden')
  " We've closed the last window for this buffer. If bufhidden was 'unload',
  " 'delete', or 'wipe', manually do that to the buffer.
  if !empty(l:prev_bufhidden) && l:prev_bufhidden != 'hide'
    exec 'b' . l:prev_bufhidden . '! ' . l:bufnr
  endif
endfunction

augroup StickyBuf
  au!
  autocmd BufEnter * call <sid>MakeStickyBuf()
  autocmd WinClosed * call <sid>RestoreBufHidden(expand('<afile>'))
augroup END
