" Detect filetypes
au BufRead,BufNewFile *.jinja2,*.j2 setlocal ft=html
au BufRead,BufNewFile *.snippets setlocal ft=snippets
au BufRead,BufNewFile *.js setlocal ft=javascript.jsx
au BufRead,BufNewFile *.md setlocal ft=markdown
au BufRead,BufNewFile *.go setlocal ft=go
au BufRead,BufNewFile *.thrift setlocal filetype=thrift
