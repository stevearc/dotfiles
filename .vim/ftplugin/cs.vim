set completeopt=longest,menuone,preview
set previewheight=5
" Use % to jump between region/endregion
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

nnoremap <buffer> K :call OmniSharp#TypeLookupWithoutDocumentation()<CR>

" The following commands are contextual, based on the cursor position.
nnoremap <buffer> gd :OmniSharpGotoDefinition<CR>
nnoremap <buffer> <Leader>fi :OmniSharpFindImplementations<CR>
nnoremap <buffer> <Leader>fs :OmniSharpFindSymbol<CR>
nnoremap <buffer> <Leader>fu :OmniSharpFindUsages<CR>

" Finds members in the current buffer
nnoremap <buffer> <Leader>fm :OmniSharpFindMembers<CR>

" Cursor can be anywhere on the line containing an issue
nnoremap <buffer> <Leader>x  :OmniSharpFixIssue<CR>
nnoremap <buffer> <Leader>fx :OmniSharpFixUsings<CR>
nnoremap <buffer> <Leader>tt :OmniSharpTypeLookup<CR>
nnoremap <buffer> <Leader>dc :OmniSharpDocumentation<CR>

" Navigate up and down by method/property/field
nnoremap <buffer> [[ :OmniSharpNavigateUp<CR>
nnoremap <buffer> ]] :OmniSharpNavigateDown<CR>

nnoremap <Leader><Space> :OmniSharpGetCodeActions<CR>
xnoremap <Leader><Space> :call OmniSharp#GetCodeActions('visual')<CR>

nnoremap <Leader>r :OmniSharpRename<CR>
" Rename without dialog - with cursor on the symbol to rename: `:Rename newname`
command! -nargs=1 Rename :call OmniSharp#RenameTo("<args>")

nnoremap <Leader>f :call csformat#FormatPreserveCursor()<CR>

augroup csfmt
  autocmd!
  autocmd BufWritePre *.cs call csformat#SmartFormat()
augroup END
