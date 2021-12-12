aug MyFiletypes
  au!
  au BufRead,BufNewFile *.js,*.js.flow setlocal ft=javascriptreact
  au BufRead,BufNewFile *.cconf setf python
  au BufRead,BufNewFile *.frag setlocal ft=glsl
aug END
