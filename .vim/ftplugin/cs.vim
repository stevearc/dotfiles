" Use % to jump between region/endregion
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

let b:ale_linters = ['OmniSharp']

let g:OmniSharp_server_stdio = 1

nnoremap <buffer> K :call OmniSharp#actions#documentation#TypeLookup()<CR>

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

nnoremap <buffer> <F5> :OmniSharpRestartAllServers<CR>

augroup csfmt
  autocmd! * <buffer>
  autocmd BufWriteCmd <buffer> call smartformat#Format('cs', 'call OmniSharp#actions#format#Format({->execute("noau w")})')
augroup END
augroup csopts
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal tw=100 foldmethod=syntax
augroup END
