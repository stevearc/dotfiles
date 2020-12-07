local themes = require('telescope.themes')
local actions = require('telescope.actions')
local path = require('telescope.path')

local M = {}

function open_existing_or_new_tab(prompt_bufnr)
  local entry = actions.get_selected_entry()
  actions.close(prompt_bufnr)

  if not entry then
    print("[telescope] Nothing currently selected")
    return
  end

  local filename = entry.path or entry.filename
  filename = path.normalize(filename, vim.fn.getcwd())

  local tabidx = 1
  while true do
    local status, tabnum = pcall(vim.api.nvim_tabpage_get_number, tabidx)
    if not status then break end
    local wins = vim.api.nvim_tabpage_list_wins(tabnum)
    for _,winid in ipairs(wins) do
      local bufnr = vim.api.nvim_win_get_buf(winid)
      local bufname = path.normalize(vim.api.nvim_buf_get_name(bufnr), vim.fn.getcwd())
      if bufname == filename or bufnr == entry.bufnr then
        vim.api.nvim_set_current_tabpage(tabnum)
        vim.api.nvim_set_current_win(winid)
        return
      end
    end
    tabidx = tabidx + 1
  end

  if entry.bufnr then
    vim.cmd(string.format(":tab sb %d", entry.bufnr))
  else
    vim.cmd(string.format(":tabedit %s", filename))
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
  end
end

M.find_files = function()
  require('telescope.builtin').find_files({
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<C-t>', open_existing_or_new_tab)
      return true
    end
  })
end

M.buffers = function()
  local opts = themes.get_dropdown{
    previewer = false,
  }
  opts.attach_mappings = function(prompt_bufnr, map)
    map('i', '<C-t>', open_existing_or_new_tab)
    return true
  end
  require('telescope.builtin').buffers(opts)

end

return M
