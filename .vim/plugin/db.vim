let g:db_ui_auto_execute_table_helpers = 1
if g:nerd_font
  let g:db_ui_use_nerd_fonts = 1
endif
let g:db_ui_force_echo_notifications = 1

let g:db_ui_table_helpers = {
\   'postgresql': {
\     'Count': 'select count(*) from "{table}"',
\ 		'Explain': 'EXPLAIN ANALYZE {last_query}',
\   },
\   'sqlite': {
\     'Count': 'select count(*) from "{table}"',
\     'Schema': '.schema --indent "{table}"',
\   },
\   'mysql': {
\     'Count': 'select count(*) from "{table}"',
\   },
\ }
