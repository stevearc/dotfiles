iabbr <buffer> inn is nonnull

augroup hackfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if @format is in the top
  autocmd BufWritePre <buffer> call hackfmt#SmartFormat()
augroup END
