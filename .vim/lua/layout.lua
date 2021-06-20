local M = {}

local layouts = {}

local function simplify_layout(layout, allowed_winids)
  local type = layout[1]
  if type == 'leaf' then
    local winid = layout[2]
    if allowed_winids[winid] == nil then
      return nil
    else
      return layout
    end
  else
    local children = layout[2]
    local new_children = {}
    for _,child in ipairs(children) do
      local new_child = simplify_layout(child, allowed_winids)
      if new_child ~= nil then
        table.insert(new_children, new_child)
      end
    end
    if vim.tbl_count(new_children) == 0 then
      return nil
    elseif vim.tbl_count(new_children) == 1 then
      return {'leaf', new_children[1]}
    else
      return {type, new_children}
    end
  end
end

M.save_layout = function(name)
  local win_to_buf = {}
  for _,winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    -- I don't care about unlisted bufs
    if vim.api.nvim_buf_get_option(bufnr, 'buflisted') then
      win_to_buf[winid] = vim.api.nvim_buf_get_name(bufnr)
    end
  end
  layouts[name] = {
    windows = simplify_layout(vim.fn.winlayout(), win_to_buf),
    win_to_buf = win_to_buf,
  }
end

local function restore_windows(windows, win_to_bufnr)
  local type = windows[1]
  if type == 'leaf' then
    local winid = windows[2]
    local bufnr = win_to_bufnr[winid]
    if bufnr then
      vim.api.nvim_win_set_buf(0, bufnr)
      vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
    end
  else
    local cmd = type == 'row' and 'vsplit' or 'split'
    local children = windows[2]
    for i,child in ipairs(children) do
      if i > 1 then
        vim.cmd(cmd)
      end
      restore_windows(child, win_to_bufnr)
    end
  end
end

M.restore_layout = function(name)
  local layout = layouts[name]
  if not layout then
    print(string.format("Layout '%s' not found", name))
    return
  end
  local win_to_bufnr = {}
  for winid,bufname in pairs(layout.win_to_buf) do
    win_to_bufnr[winid] = vim.fn.bufadd(bufname)
  end
  vim.cmd('silent only')
  local splitbelow = vim.nvim_get_option('splitbelow')
  local splitright = vim.nvim_get_option('splitright')
  vim.nvim_set_option('splitbelow', true)
  vim.nvim_set_option('splitright', true)
  restore_windows(layout.windows, win_to_bufnr)
  vim.nvim_set_option('splitbelow', splitbelow)
  vim.nvim_set_option('splitright', splitright)
  vim.cmd('wincmd =')
end

local stack_ptr = 0
M.push_layout = function()
  M.save_layout(stack_ptr)
  stack_ptr = stack_ptr + 1
end

M.pop_layout = function()
  if stack_ptr == 0 then
    print("No layout to pop")
    return
  end
  stack_ptr = stack_ptr - 1
  M.restore_layout(stack_ptr)
end

M.list_layouts = function()
  return vim.tbl_keys(layouts)
end

M.pick_with_telescope = function()
  local themes = require('telescope.themes')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local opts = themes.get_dropdown{
    previewer = false,
  }
  pickers.new(opts, {
    prompt_title = 'Layouts',
    finder = finders.new_table {
      results = M.list_layouts()
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        M.restore_layout(selection.value)
      end)

      return true
    end
  }):find()
end

return M
