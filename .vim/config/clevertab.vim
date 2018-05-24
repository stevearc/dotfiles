" Attempt to expand a snippet. If no snippet exists, either autocomplete or
" insert a tab
let g:ulti_expand_or_jump_res = 0 "default value, just set once
let g:autocomplete_cmd = "\<C-x>\<C-o>"
function! CleverTab()
    call UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res == 0
      if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
          return "\<Tab>"
      elseif &omnifunc == ''
          return "\<C-n>"
      else
          return g:autocomplete_cmd
      endif
    else
      return ''
    endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>
