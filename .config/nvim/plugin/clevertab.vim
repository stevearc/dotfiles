if g:snippet_engine != 'vsnip'
  finish
endif

let g:autocomplete_cmd = "\<C-x>\<C-o>"
function! CleverTab() abort
  if vsnip#available(1)
    if pumvisible()
      call feedkeys("\<C-x>\<C-x>")
    endif
    call Vsnip_expand_or_jump()
    return ''
  elseif pumvisible()
    return "\<C-n>"
  elseif strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"
  elseif &omnifunc == ''
    return "\<C-p>"
  else
    return g:autocomplete_cmd
  endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>

function! Vsnip_expand_or_jump()
  let l:ctx = {}
  function! l:ctx.callback() abort
    let l:context = vsnip#get_context()
    let l:session = vsnip#get_session()
    if !empty(l:context)
      call vsnip#expand()
    elseif !empty(l:session) && l:session.jumpable(1)
      call l:session.jump(1)
    endif
  endfunction

  " This is needed to keep normal-mode during 0ms to prevent CompleteDone handling by LSP Client.
  let l:maybe_complete_done = !empty(v:completed_item) && !empty(v:completed_item.user_data)
  if l:maybe_complete_done
    call timer_start(0, { -> l:ctx.callback() })
  else
    call l:ctx.callback()
  endif
endfunction
