local themes = require("telescope.themes")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local dirs = {}

local sep = package.config:sub(1, 1)
local function get_cache_file()
  local cache_dir = vim.fn.stdpath("cache")
  return cache_dir .. sep .. "recent_dirs.json"
end

local function load_cache()
  local filename = get_cache_file()
  local file = io.open(filename, "r")
  if file then
    local ok, data = pcall(file.read, file)
    if ok then
      dirs = vim.json.decode(data)
    end
    file:close()
  end
end

local function save_cache()
  local filename = get_cache_file()
  local file = io.open(filename, "w")
  file:write(vim.json.encode(dirs))
  file:close()
end

local function on_dir_changed(dir)
  dirs[dir] = 1
  save_cache()
end

function stevearc._on_dir_changed()
  on_dir_changed(vim.v.event.cwd)
end

local function remove_recent_dir(dir)
  dirs[dir] = nil
  save_cache()
end

local function display_path(dir)
  local home = os.getenv("HOME")
  local idx, chars = string.find(dir, home)
  if idx == 1 then
    dir = "~" .. string.sub(dir, idx + chars)
  end
  return dir
end

local function open_project_tab(dir)
  local has_any_bufs = false
  local getopt = vim.api.nvim_buf_get_option
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if getopt(bufnr, "buflisted") and getopt(bufnr, "buftype") == "" and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      has_any_bufs = true
      break
    end
  end
  if has_any_bufs then
    vim.cmd("tabnew")
    vim.cmd("tcd " .. dir)
  else
    vim.cmd("cd " .. dir)
  end
end

function stevearc.telescope_pick_project()
  local opts = themes.get_dropdown({
    previewer = false,
  })
  pickers.new(opts, {
    prompt_title = "Projects",
    finder = finders.new_table({
      results = vim.tbl_keys(dirs),
      entry_maker = function(dir)
        local entry = {}
        local display = display_path(dir)
        entry.value = dir
        entry.ordinal = display
        entry.display = display
        return entry
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_tab:replace(function()
        local selection = state.get_selected_entry()
        actions.close(prompt_bufnr)
        open_project_tab(selection.value)
      end)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        actions.close(prompt_bufnr)

        for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
          local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
          local dir = vim.fn.getcwd(0, tabnr)
          if dir == selection.value then
            vim.api.nvim_set_current_tabpage(tabpage)
            return
          end
        end
        open_project_tab(selection.value)
      end)

      map("i", "<C-d>", function(prompt_bufnr)
        local current_picker = state.get_current_picker(prompt_bufnr)
        current_picker:delete_selection(function(selection)
          remove_recent_dir(selection.value)
        end)
      end)
      return true
    end,
  }):find()
end

vim.defer_fn(function()
  load_cache()
  on_dir_changed(vim.loop.cwd())
  vim.cmd([[augroup recent_dirs
  au!
  au DirChanged lua stevearc._on_dir_changed()
augroup END]])
end, 100)
