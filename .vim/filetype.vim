" Detect filetypes
au BufRead,BufNewFile *.jinja2,*.j2 setlocal ft=html
au BufRead,BufNewFile *.snippets setlocal ft=snippets
au BufRead,BufNewFile *.js setlocal ft=javascript
au BufRead,BufNewFile *.md setlocal ft=markdown
au BufRead,BufNewFile *.go setlocal ft=go

" Broken Arrow
aug BAFileType
  au!
  au BufRead,BufNewFile *.json,*.scene,*.prefab,*.particle,*.fx,*.material,*.shading,*.map* :call SetBAFileType()
aug END

function! SetBAFileType()
  if getline(1) =~ '^#!.*\<cson\>'
    setlocal ft=coffee
  else
    setlocal ft=json
  endif
endfunction
