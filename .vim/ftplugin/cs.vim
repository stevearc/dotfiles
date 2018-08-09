" Use % to jump between region/endregion
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

nnoremap <buffer> K :call OmniSharp#TypeLookupWithoutDocumentation()<CR>

" The following commands are contextual, based on the cursor position.
nnoremap <buffer> gd m':OmniSharpGotoDefinition<CR>
nnoremap <buffer> gD m':$tab split<CR>:OmniSharpGotoDefinition<CR>
nnoremap <buffer> gi :OmniSharpFindImplementations<CR>
nnoremap <buffer> gs :OmniSharpFindSymbol 
nnoremap <buffer> gr :OmniSharpFindUsages<CR>
nnoremap <buffer> gm :OmniSharpFindMembers<CR>

nnoremap <buffer> <leader>o :OmniSharpFixUsings<CR>

nnoremap <buffer> <Leader>k :OmniSharpTypeLookup<CR>
nnoremap <buffer> <Leader>dc :OmniSharpDocumentation<CR>

" Navigate up and down by method/property/field
nnoremap <buffer> [[ :OmniSharpNavigateUp<CR>zz
nnoremap <buffer> ]] :OmniSharpNavigateDown<CR>zz

nnoremap <buffer> <Leader><Space> :OmniSharpGetCodeActions<CR>
xnoremap <buffer> <Leader><Space> :call OmniSharp#GetCodeActions('visual')<CR>

nnoremap <buffer> <Leader>r :OmniSharpRename<CR>
" Rename without dialog - with cursor on the symbol to rename: `:Rename newname`
command! -buffer -nargs=1 Rename :call OmniSharp#RenameTo("<args>")

nnoremap <buffer> <Leader>f :OmniSharpCodeFormat<CR>

augroup csfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('cs', 'OmniSharpCodeFormat')
augroup END
augroup csopts
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal tw=100 foldmethod=syntax
augroup END