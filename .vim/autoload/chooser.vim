if !exists('g:chooser_ui')
  let g:chooser_ui = 'ctrlp'
endif

function! chooser#Choose(title, items, callback, options) abort
  if len(a:items) == 0
    if get(a:options, 'warn_on_empty', 0)
      echoerr "No options available"
    endif
    return
  elseif len(a:items) == 1 && get(a:options, 'auto_choose_one', 0)
    call call(a:callback, [a:items[0]])
    return
  endif

  if g:chooser_ui ==? 'ctrlp'
    let ext_data = get(g:ctrlp_ext_vars, s:ctrlp_idx)
    let ext_data.lname = a:title
    let s:ctrlp_list = a:items
    let s:callback = a:callback
    call ctrlp#init(s:ctrlp_id)
  elseif g:chooser_ui ==? 'fzf'
    let s:callback = a:callback
    call fzf#run({
    \ 'source': a:items,
    \ 'down': '10%',
    \ 'sink': function('s:fzf_Callback')})
  else
    let labels = ["   " . a:title]
    let idx = 1
    for item in a:items
      call add(labels, idx . ") " . item)
      let idx += 1
    endfor
    let choice = inputlist(labels)
    if choice > 0
      call call(a:callback, [a:items[choice-1]])
    endif
  endif
endfunction

" Ctrlp {{{ "

if g:chooser_ui ==? 'ctrlp'
  let s:ctrlp_idx = len(g:ctrlp_ext_vars)
  call add(g:ctrlp_ext_vars, {
    \ 'init': 'chooser#ctrlp_GetData()',
    \ 'accept': 'chooser#ctrlp_Callback',
    \ 'lname': 'chooser',
    \ 'sname': 'chooser',
    \ 'type': 'line',
    \ })

  let s:ctrlp_id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
endif

function! chooser#ctrlp_GetData()
  return s:ctrlp_list
endfunction

function! chooser#ctrlp_Callback(mode, str)
	call ctrlp#exit()
  call call(s:callback, [a:str])
endfunction

" }}} Ctrlp "

" Fzf {{{ "

function! s:fzf_Callback(str)
  call call(s:callback, [a:str])
endfunction

" }}} Fzf "

" vim:fdm=marker:
