" Define mappings

se bufhidden=wipe

nnoremap <silent><buffer><expr> <CR> defx#do_action('open')
nnoremap <silent><buffer><expr> c defx#do_action('copy')
nnoremap <silent><buffer><expr> m defx#do_action('move')
nnoremap <silent><buffer><expr> p defx#do_action('paste')
nnoremap <silent><buffer><expr> l defx#do_action('open')
nnoremap <silent><buffer><expr> <C-v> defx#do_action('open', 'vsplit')
nnoremap <silent><buffer><expr> P defx#do_action('preview')
nnoremap <silent><buffer><expr> o defx#do_action('open_tree', 'toggle')
nnoremap <silent><buffer><expr> O defx#do_action('open_tree', 'recursive', 'toggle')
nnoremap <silent><buffer><expr> d defx#do_action('new_directory')
nnoremap <silent><buffer><expr> % defx#do_action('new_file')
nnoremap <silent><buffer><expr> M defx#do_action('new_multiple_files')
nnoremap <silent><buffer><expr> C defx#do_action('toggle_columns', 'indent:icons:filename:type:size:time')
nnoremap <silent><buffer><expr> S defx#do_action('toggle_sort', 'time')
nnoremap <silent><buffer><expr> D defx#do_action('remove')
nnoremap <silent><buffer><expr> r defx#do_action('rename')
nnoremap <silent><buffer><expr> ! defx#do_action('execute_command')
nnoremap <silent><buffer><expr> x defx#do_action('execute_system')
nnoremap <silent><buffer><expr> yy defx#do_action('yank_path')
nnoremap <silent><buffer><expr> . defx#do_action('toggle_ignored_files')
nnoremap <silent><buffer><expr> ; defx#do_action('repeat')
nnoremap <silent><buffer><expr> h defx#do_action('cd', ['..'])
nnoremap <silent><buffer><expr> - defx#do_action('cd', ['..'])
nnoremap <silent><buffer><expr> ~ defx#do_action('cd')
nnoremap <silent><buffer><expr> q defx#do_action('quit')
nnoremap <silent><buffer><expr> <Space> defx#do_action('toggle_select') . 'j'
nnoremap <silent><buffer><expr> * defx#do_action('toggle_select_all')
nnoremap <silent><buffer><expr> # defx#do_action('clear_select_all')
nnoremap <silent><buffer><expr> j line('.') == line('$') ? 'gg' : 'j'
nnoremap <silent><buffer><expr> k line('.') == 1 ? 'G' : 'k'
nnoremap <silent><buffer><expr> <C-l> defx#do_action('redraw')
nnoremap <silent><buffer><expr> <C-g> defx#do_action('print')
nnoremap <silent><buffer><expr> > defx#do_action('resize', defx#get_context().winwidth + 10)
nnoremap <silent><buffer><expr> < defx#do_action('resize', defx#get_context().winwidth - 10)
nnoremap <silent><buffer> t <cmd>call <sid>OpenTerm()<CR>
nnoremap <silent><buffer> <leader>t <cmd>call <sid>FindDirFiles()<CR>
nnoremap <silent><buffer> H <cmd>call nvim_set_current_dir(<sid>GetDefxDir())<CR>

fun! s:GetDefxDir() abort
  let l:candidate = defx#get_candidate()
  if l:candidate['is_directory']
    let l:mod = ':p:h:h'
  else
    let l:mod = ':p:h'
  endif
  return fnamemodify(l:candidate['action__path'], l:mod)
endfun

fun! s:FindDirFiles() abort
  let l:path = s:GetDefxDir()
  call luaeval("require('stevearc.telescope').find_files({cwd = _A, hidden=true})", l:path)
endfun

fun! s:OpenTerm() abort
  let l:path = s:GetDefxDir()
  let l:cwd = getcwd()
  exec "lcd " . l:path
  terminal
  exec "lcd " . l:cwd
endfun

fun! s:Livegrep() abort
  let l:path = s:GetDefxDir()
  call luaeval("require('telescope.builtin').live_grep(_A)", {'cwd': l:path})
endf

nnoremap <buffer> <leader>g <cmd>call <sid>Livegrep()<cr>

fun! s:Subgrep(args) abort
  let l:path = s:GetDefxDir()
  exec "silent grep '" . a:args . "' '" . l:path . "'"
  lua require'qf_helper'.open('c', {enter=true})
endf

command! -buffer -bar -nargs=+ Sgrep call <sid>Subgrep('<args>')
