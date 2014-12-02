" Detect filetypes
au BufRead,BufNewFile *.jinja2 setlocal ft=html
au BufRead,BufNewFile *.snippets setlocal ft=snippets
au BufRead,BufNewFile *.js setlocal ft=javascript
au BufRead,BufNewFile *.md setlocal ft=markdown
au BufRead,BufNewFile *.go setlocal ft=go

" Broken Arrow
aug BAFileType
  au!
  au BufRead,BufNewFile *.scene,*.prefab,*.particle,*.emitter,*.map,*.material :call SetBAFileType()
aug END

function! SetBAFileType()
  if getline(1) =~ '^#!.*\<cson\>'
    setlocal ft=coffee
  else
    setlocal ft=javascript
  endif
endfunction
