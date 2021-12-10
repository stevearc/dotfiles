vim.g.db_ui_auto_execute_table_helpers = 1
if vim.g.nerd_font then
  vim.g.db_ui_use_nerd_fonts = 1
end
vim.g.db_ui_force_echo_notifications = 1

vim.g.db_ui_table_helpers = {
  postgresql = {
    Count = 'select count(*) from "{table}"',
    Explain = "EXPLAIN ANALYZE {last_query}",
  },
  sqlite = {
    Count = 'select count(*) from "{table}"',
    Schema = '.schema --indent "{table}"',
  },
  mysql = {
    Count = 'select count(*) from "{table}"',
  },
}

vim.cmd([[
aug DBUI
  au!
  au BufEnter * if !empty(get(b:, 'db')) | se nobuflisted | endif
aug END
]])
