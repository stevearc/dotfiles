local themes = require("telescope.themes")
local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local M = {}

M.myles_find_files = function()
  require("myles").find_files({
    previewer = false,
  })
end

M.select = function(title, items, callback)
  local opts = themes.get_dropdown({
    previewer = false,
  })
  pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table({
      results = items,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        if type(callback) == "string" then
          vim.call(callback, selection.value)
        else
          callback(selection.value)
        end
      end)

      return true
    end,
  }):find()
end

return M
