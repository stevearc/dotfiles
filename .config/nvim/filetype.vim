" Detect filetypes
au BufRead,BufNewFile *.snippets setlocal ft=snippets
au BufRead,BufNewFile *.js setlocal ft=javascript.jsx
au BufRead,BufNewFile *.js.flow setlocal ft=javascript.jsx
au BufRead,BufNewFile *.md setlocal ft=markdown
au BufRead,BufNewFile *.go setlocal ft=go
au BufRead,BufNewFile *.thrift setlocal filetype=thrift
au BufRead,BufNewFile *.cconf setlocal filetype=python
au BufRead,BufNewFile *.snippets setlocal filetype=snippets
au BufRead,BufNewFile *.frag setf glsl
