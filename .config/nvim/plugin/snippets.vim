let g:vsnip_snippet_dirs = [
      \ $HOME.'/.vim/vsnip',
      \ $HOME.'/.config/nvim/vsnip',
      \ ]
let g:ulti_expand_or_jump_res = 0 "default value, just set once
function! Vsnip_jump(direction) abort
  let l:session = vsnip#get_session()
  if !empty(l:session) && l:session.jumpable(a:direction)
    call l:session.jump(a:direction)
  endif
endfunction
function! ForwardsInInsert() abort
  if vsnip#jumpable(1)
    call Vsnip_jump(1)
  elseif g:completion_plugin == 'completion-nvim'
    lua require'completion'.nextSource()
  endif
endfunction
function! BackwardsInInsert() abort
  if vsnip#jumpable(-1)
    call Vsnip_jump(-1)
  elseif g:completion_plugin == 'completion-nvim'
    lua require'completion'.prevSource()
  endif
endfunction

let g:vsnip_filetypes = {}
let g:vsnip_filetypes.javascriptreact = ['javascript']
let g:vsnip_filetypes.typescriptreact = ['typescript']
smap <Tab> <Plug>(vsnip-jump-next)
xmap <Tab> <Plug>(vsnip-cut-text)
smap <C-h> <Plug>(vsnip-jump-prev)
imap <C-h> <cmd>call BackwardsInInsert()<cr>
smap <C-l> <Plug>(vsnip-jump-next)
imap <C-l> <cmd>call ForwardsInInsert()<cr>
" Clear Vsnip session when we switch to normal mode.
if exists('*vsnip#deactivate')
  aug ClearVsnipSession
    au!
    " Can't use InsertLeave here because that fires when we go to select mode
    au CursorHold * call vsnip#deactivate()
  aug END
endif
