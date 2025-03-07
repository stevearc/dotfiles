local M = {}

---@class Tag
---@field cmd string
---@field filename string
---@field kind string
---@field name string
---@field static integer

---@param opts {max_tag_len?: integer, show_line?: boolean}
---@return fun(tag: Tag): table
local function gen_entry_maker(opts)
  local entry_display = require("telescope.pickers.entry_display")
  local utils = require("telescope.utils")

  local display_items = {
    { width = opts.max_tag_len or 30 },
    { remaining = true },
  }
  if opts.show_line then
    table.insert(display_items, { width = 30 })
  end
  local displayer = entry_display.create({
    separator = " │ ",
    items = display_items,
  })

  local make_display = function(entry)
    local filename = utils.transform_path(opts, entry.filename)

    local cmd
    if opts.show_line then
      cmd = entry.cmd
    end

    return displayer({
      entry.tag,
      filename,
      cmd,
    })
  end

  return function(tag)
    return {
      ordinal = tag.filename .. ": " .. tag.name,
      display = make_display,
      cmd = tag.cmd,
      tag = tag.name,
      filename = tag.filename,
    }
  end
end

local function new_previewer(opts)
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local determine_jump = function(self, bufnr, entry)
    pcall(vim.fn.matchdelete, self.state.hl_id, self.state.winid)
    local search_pat = string.sub(entry.cmd, 2, #entry.cmd - 2)
    vim.cmd("norm! gg")
    vim.fn.search(search_pat, "W")
    vim.cmd("norm! zz")
    self.state.hl_id = vim.fn.matchadd("TelescopePreviewMatch", search_pat)
  end

  return previewers.new_buffer_previewer({
    title = "Tags Preview",
    teardown = function(self)
      if self.state and self.state.hl_id then
        pcall(vim.fn.matchdelete, self.state.hl_id, self.state.hl_win)
        self.state.hl_id = nil
      elseif self.state and self.state.last_set_bufnr and vim.api.nvim_buf_is_valid(self.state.last_set_bufnr) then
        vim.api.nvim_buf_clear_namespace(self.state.last_set_bufnr, ns_previewer, 0, -1)
      end
    end,

    get_buffer_by_name = function(_, entry) return entry.filename end,

    define_preview = function(self, entry, status)
      conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          pcall(vim.api.nvim_buf_call, bufnr, function() determine_jump(self, bufnr, entry) end)
        end,
      })
    end,
  })
end

---@param word string
---@param candidates Tag[]
---@param callback fun(idx: integer)
local function choose(word, candidates, callback)
  local ok, pickers = pcall(require, "telescope.pickers")
  if ok then
    local actions = require("telescope.actions")
    local action_set = require("telescope.actions.set")
    local make_entry = require("telescope.make_entry")
    local finders = require("telescope.finders")
    local action_state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")
    local conf = require("telescope.config").values
    local results = candidates
    local max_tag_len = vim.api.nvim_strwidth(word)
    for _, tag in ipairs(candidates) do
      local length = vim.api.nvim_strwidth(tag.name)
      if length > max_tag_len then
        max_tag_len = length
      end
    end
    local opts = { max_tag_len = max_tag_len, show_line = false }

    pickers
      .new(opts, {
        prompt_title = string.format("Jump to %s", word),
        finder = finders.new_table({
          results = results,
          entry_maker = gen_entry_maker(opts),
        }),
        previewer = new_previewer(opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function()
          action_set.select:replace(function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            callback(selection.index)
          end)
          return true
        end,
      })
      :find()
  else
    vim.ui.select(candidates, {
      prompt = string.format("Jump to %s", word),
      format_item = function(item)
        local cmd = string.gsub(item.cmd, "^/%^", "")
        cmd = string.gsub(cmd, "%$/$", "")
        return string.format("%s: %s", item.filename, cmd)
      end,
      kind = "tag",
    }, function(_, idx)
      if idx then
        callback(idx)
      end
    end)
  end
end

---@param tag Tag
local function jump_to_tag(tag)
  vim.cmd.edit({ args = { tag.filename } })
  local search_reg = vim.fn.getreg("/")
  vim.cmd(tag.cmd)
  vim.fn.setreg("/", search_reg)
  vim.cmd.nohlsearch()
end

---@param word string
---@param candidates Tag[]
---@param regex boolean
local function jump_to(word, candidates, regex)
  if #candidates == 0 then
    vim.notify(string.format("No tag found for '%s'", word), vim.log.levels.WARN)
  elseif #candidates == 1 then
    jump_to_tag(candidates[1])
  else
    choose(word, candidates, function(idx) jump_to_tag(candidates[idx]) end)
  end
end

---@param word string
---@return string
local function make_exact(word)
  local ret = word
  if string.find(word, "%^") ~= 1 then
    ret = "^" .. ret
  end
  if not string.find(word, "%$", #word - 1) then
    ret = ret .. "$"
  end
  return ret
end

---@param word? string
---@param opts? {match?: "smart" | "exact" | "raw"}
M.goto_definition = function(word, opts)
  word = word or vim.fn.expand("<cword>")
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    match = "smart",
  })
  local candidates
  if opts.match == "smart" then
    local term = make_exact(word)
    if term ~= word then
      candidates = vim.fn.taglist(term)
      if #candidates > 0 then
        jump_to(word, candidates, false)
        return
      end
    end
    jump_to(word, vim.fn.taglist(word), true)
  elseif opts.match == "exact" then
    jump_to(word, vim.fn.taglist(make_exact(word)), false)
  elseif opts.match == "raw" then
    jump_to(word, vim.fn.taglist(word), false)
  else
    vim.notify(string.format("Unknown match type '%s'", opts.match), vim.log.levels.ERROR)
  end
end

return M
