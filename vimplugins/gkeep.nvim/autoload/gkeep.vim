function! gkeep#preload() abort
  if !exists('*_gkeep_preload')
    runtime! plugin/rplugin.vim
  endif
  call _gkeep_preload()
endfunction
