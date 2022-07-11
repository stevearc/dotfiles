aug MyFiletypes
  au!
  au BufRead,BufNewFile *.js,*.js.flow setlocal ft=javascript.jsx
  au BufRead,BufNewFile *.tsx setlocal ft=typescript.tsx
  au BufRead,BufNewFile *.cconf setfiletype python
  au BufRead,BufNewFile *.frag setlocal ft=glsl
aug END
