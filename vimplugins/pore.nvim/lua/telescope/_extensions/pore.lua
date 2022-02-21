local api = require("pore.api")
local async = require("pore.async")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local sorters = require("telescope.sorters")
local pickers = require("telescope.pickers")
local telescope = require("telescope")

-- This taken from finders.lua in telescope.nvim
local _callable_obj = function()
  local obj = {}

  obj.__index = obj
  obj.__call = function(t, ...)
    return t:_find(...)
  end

  obj.close = function() end

  return obj
end

local DynamicAsyncFinder = _callable_obj()

function DynamicAsyncFinder:new(opts)
  opts = opts or {}

  local obj = setmetatable({
    curr_buf = opts.curr_buf,
    _find = opts.fn,
    entry_maker = opts.entry_maker,
  }, self)

  return obj
end

local function process_search_results(search_results)
  local results = {}
  for _, result in ipairs(search_results) do
    if result.lines and result.lines[1] then
      for _, line in ipairs(result.lines) do
        table.insert(results, string.format("%s:%d:0:%s", result.file, line.number, line.text))
      end
    else
      table.insert(results, string.format("%s:1:0:", result.file))
    end
  end
  return results
end

-- sync picker
local function pore_picker(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
  local index = api.get_file_index(opts.cwd, nil, {})
  index:update()

  local finder = finders.new_dynamic({
    fn = function(prompt)
      return process_search_results(index:search(prompt))
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
  })

  pickers.new(opts, {
    prompt_title = "Text Search",
    finder = finder,
    sorter = sorters.empty(),
    previewer = conf.grep_previewer(opts),
  }):find()
end

local function pore_picker_async(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
  local index = api.get_file_index(opts.cwd, nil, {})
  index:update()

  local search = function(self, prompt, process_result, process_complete)
    async.run(index.search_async, function(err, search_results)
      if err then
        vim.api.nvim_err_writeln(string.format("Search error: %s", err))
      else
        for _, result in ipairs(process_search_results(search_results)) do
          process_result(self.entry_maker(result))
        end
      end
      process_complete()
    end, 100, index, prompt)
  end

  pickers.new(opts, {
    prompt_title = "Text Search",
    finder = DynamicAsyncFinder:new({
      curr_buf = vim.api.nvim_get_current_buf(),
      fn = search,
      entry_maker = make_entry.gen_from_vimgrep(opts),
    }),
    sorter = sorters.empty(),
    previewer = conf.grep_previewer(opts),
  }):find()
end

return telescope.register_extension({
  exports = {
    pore = pore_picker_async,
  },
})
