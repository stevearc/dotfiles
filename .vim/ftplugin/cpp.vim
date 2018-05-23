augroup cppfmt
  autocmd!
  " This calls out to Neoformat, but only if file is in a whitelisted directory
  autocmd BufWritePre *.h,*.cpp,*.c call clangformat#SmartFormat()
augroup END

