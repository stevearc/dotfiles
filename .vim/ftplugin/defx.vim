" Define mappings

nnoremap <silent><buffer><expr> <CR>
  \ defx#do_action('open')
nnoremap <silent><buffer><expr> c
  \ defx#do_action('copy')
nnoremap <silent><buffer><expr> m
  \ defx#do_action('move')
nnoremap <silent><buffer><expr> p
  \ defx#do_action('paste')
nnoremap <silent><buffer><expr> l
  \ defx#do_action('open')
nnoremap <silent><buffer><expr> <C-v>
  \ defx#do_action('open', 'vsplit')
nnoremap <silent><buffer><expr> P
  \ defx#do_action('preview')
nnoremap <silent><buffer><expr> o
  \ defx#do_action('open_tree', 'toggle')
nnoremap <silent><buffer><expr> O
  \ defx#do_action('open_tree', 'recursive', 'toggle')
nnoremap <silent><buffer><expr> d
  \ defx#do_action('new_directory')
nnoremap <silent><buffer><expr> %
  \ defx#do_action('new_file')
nnoremap <silent><buffer><expr> M
  \ defx#do_action('new_multiple_files')
nnoremap <silent><buffer><expr> C
  \ defx#do_action('toggle_columns',
  \                'mark:indent:icon:filename:type:size:time')
nnoremap <silent><buffer><expr> S
  \ defx#do_action('toggle_sort', 'time')
nnoremap <silent><buffer><expr> D
  \ defx#do_action('remove')
nnoremap <silent><buffer><expr> <leader>n
  \ defx#do_action('rename')
nnoremap <silent><buffer><expr> !
  \ defx#do_action('execute_command')
nnoremap <silent><buffer><expr> x
  \ defx#do_action('execute_system')
nnoremap <silent><buffer><expr> yy
  \ defx#do_action('yank_path')
nnoremap <silent><buffer><expr> .
  \ defx#do_action('toggle_ignored_files')
nnoremap <silent><buffer><expr> ;
  \ defx#do_action('repeat')
nnoremap <silent><buffer><expr> h
  \ defx#do_action('cd', ['..'])
nnoremap <silent><buffer><expr> -
  \ defx#do_action('cd', ['..'])
nnoremap <silent><buffer><expr> ~
  \ defx#do_action('cd')
nnoremap <silent><buffer><expr> q
  \ defx#do_action('quit')
nnoremap <silent><buffer><expr> <Space>
  \ defx#do_action('toggle_select') . 'j'
nnoremap <silent><buffer><expr> *
  \ defx#do_action('toggle_select_all')
nnoremap <silent><buffer><expr> #
  \ defx#do_action('clear_select_all')
nnoremap <silent><buffer><expr> j
  \ line('.') == line('$') ? 'gg' : 'j'
nnoremap <silent><buffer><expr> k
  \ line('.') == 1 ? 'G' : 'k'
nnoremap <silent><buffer><expr> <C-l>
  \ defx#do_action('redraw')
nnoremap <silent><buffer><expr> <C-g>
  \ defx#do_action('print')
nnoremap <silent><buffer><expr> > defx#do_action('resize',
	\ defx#get_context().winwidth + 10)
nnoremap <silent><buffer><expr> < defx#do_action('resize',
	\ defx#get_context().winwidth - 10)

fun! Subgrep() abort
  let l:path = fnamemodify(defx#get_candidate()['action__path'], ':p:h')
  call luaeval("require('telescope.builtin').live_grep(_A)", {'cwd': l:path})
endf

nnoremap <buffer> <leader>g <cmd>call Subgrep()<cr>
