safe_require('recent_dirs', "telescope", function(recent_dirs)
  local themes = require("telescope.themes")
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

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
        results = recent_dirs.get_dirs(),
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
            recent_dirs.remove_dir(selection.value)
          end)
        end)
        return true
      end,
    }):find()
  end

  vim.defer_fn(function()
    recent_dirs.load_cache()
    recent_dirs.record_dir(vim.loop.cwd())
    local aug = vim.api.nvim_create_augroup('StevearcRecentDirs', {})
    vim.api.nvim_create_autocmd('DirChanged', {
      desc = 'Record recent dir',
      group = aug,
      callback = function()
        recent_dirs.record_dir(vim.v.event.cwd)
      end,
    })
  end, 100)
end)
