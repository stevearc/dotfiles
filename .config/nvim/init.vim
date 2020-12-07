set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
if filereadable(expand('~/.local.vimrc'))
  source ~/.local.vimrc
endif
