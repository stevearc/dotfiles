if g:nerd_font
  let g:defx_columns = 'indent:icons:space:filename:type'
else
  let g:defx_columns = 'mark:indent:icon:filename:type'
endif

nnoremap <silent> - <cmd>Defx -columns=`g:defx_columns` `expand('%:p:h')` -search=`expand('%:p')` -vertical-preview -new -preview-width=100<CR>
nnoremap <leader>w <cmd>Defx -columns=`g:defx_columns` -split=vertical -winwidth=50 -direction=topleft -toggle<CR>
nnoremap <leader>W <cmd>Defx -columns=`g:defx_columns` `expand('%:p:h')` -search=`expand('%:p')` -split=vertical -winwidth=50 -direction=topleft -toggle<CR>

function! s:OpenDefxIfDirectory() abort
  try
    let l:full_path = expand(expand('%:p'))
  catch
    return
  endtry
  if isdirectory(l:full_path)
    let l:bn = bufnr()
    Defx -columns=`g:defx_columns` `expand('%:p')` -vertical-preview -new -preview-width=100
    execute "silent! bd " . l:bn
  endif
endfunction

augroup defx_config
  autocmd!
  " This handles the case when vim is opened on a directory
  autocmd BufEnter * call <sid>OpenDefxIfDirectory()
  " This handles the case when we open a directory with :edit
  autocmd BufEnter * call timer_start(2, { tid -> <sid>OpenDefxIfDirectory()})
augroup END
