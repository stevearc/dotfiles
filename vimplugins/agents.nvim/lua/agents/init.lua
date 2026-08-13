local M = {}

---@param opts? agents.SetupOpts
M.setup = function(opts)
  require("agents.config").setup(opts)
end

---@return AgentsProcess
M.get_proc = function()
  return require("agents.process").get_proc()
end

-- TODO copy my action running logic from overseer or oil
local actions = {
  send_location = {
    desc = "Send cursor location to agent",
    mode = { "n", "v" },
    callback = function()
      local util = require("agents.util")
      local window = require("agents.window")
      local location = util.get_location()
      local c = M.get_proc()
      c:send_text(location .. " ")
      util.leave_visual_mode()
      window.open_float(c.bufnr)
      vim.cmd.startinsert()
    end,
  },
  toggle_float = {
    desc = "Open agent buffer in a floating window",
    callback = function()
      local window = require("agents.window")
      local winid = window.get_float_win()
      if winid then
        vim.api.nvim_win_close(winid, true)
      else
        local c = M.get_proc()
        window.open_float(c.bufnr)
        vim.cmd.startinsert()
      end
    end,
  },
  autofill = {
    desc = "Auto implement some code",
    mode = { "n", "v" },
    callback = function()
      local util = require("agents.util")
      local location = util.get_location({ context = "line" })
      util.leave_visual_mode()
      local c = M.get_proc()
      c:send_text(
        string.format(
          "Implement the missing code in %s. No need to run tests or format the code.",
          location
        ),
        true
      )
    end,
  },
}

---@param action_name? string
M.run_action = function(action_name)
  if not action_name then
    local items = vim.tbl_filter(function(action)
      return not action.cond or action.cond()
    end, actions)
    vim.ui.select(items, {
      format_item = function(item)
        return item.desc
      end,
    }, function(action)
      if action and (not action.cond or action.cond()) then
        action.callback()
      end
    end)
  else
    local action = assert(actions[action_name])
    if action.cond and not action.cond() then
      vim.notify("Cannot " .. action.desc, vim.log.levels.ERROR)
    else
      action.callback()
    end
  end
end

---@param annotations agents.AnnotationLocation[]
M.set_annotations = function(annotations)
  require("agents.annotations").set(annotations)
end

---@param opts? {text?:string}
function M.comment_add(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" or vim.bo[bufnr].buftype ~= "" then
    vim.notify("Comments require a named file buffer", vim.log.levels.WARN)
    return nil, "Comments require a named file buffer"
  end
  local start_lnum, end_lnum = unpack(require("agents.util").range_from_selection())
  if not vim.startswith(vim.api.nvim_get_mode().mode:lower(), "v") then
    start_lnum = vim.api.nvim_win_get_cursor(0)[1]
    end_lnum = start_lnum
  end
  require("agents.util").leave_visual_mode()
  local comments = require("agents.comments")
  local clear_preview = comments.preview_range(bufnr, start_lnum, end_lnum)
  local function save(text)
    local comment, err = comments.add({
      filename = filename,
      start_lnum = start_lnum,
      end_lnum = end_lnum,
      text = text,
    })
    if not comment then
      return false, err
    end
    return true
  end
  if opts.text ~= nil then
    clear_preview()
    local comment, err = comments.add({
      filename = filename,
      start_lnum = start_lnum,
      end_lnum = end_lnum,
      text = opts.text,
    })
    if not comment then
      vim.notify(err, vim.log.levels.WARN)
    end
    return comment, err
  end
  require("agents.comment_editor").open("", save, { on_close = clear_preview })
end

---@param callback fun(comment:agents.ReviewComment)|nil
local function select_comment(callback)
  local filename = vim.api.nvim_buf_get_name(0)
  local candidates = require("agents.comments").at(filename, vim.api.nvim_win_get_cursor(0)[1])
  if #candidates == 0 then
    vim.notify("No review comment at the cursor", vim.log.levels.WARN)
    return nil, "No review comment at the cursor"
  elseif #candidates == 1 then
    return callback(candidates[1])
  else
    vim.ui.select(candidates, {
      prompt = "Select review comment",
      format_item = function(item)
        return item.text:gsub("\n.*", "")
      end,
    }, callback)
  end
end

---@param opts? {text?:string}
function M.comment_edit(opts)
  opts = opts or {}
  return select_comment(function(comment)
    local clear_preview = require("agents.comments").preview_range(
      vim.api.nvim_get_current_buf(),
      comment.start_lnum,
      comment.end_lnum
    )
    local function save(text)
      local value, err = require("agents.comments").edit(comment.id, text)
      if not value then
        return false, err
      end
      return true
    end
    if opts.text ~= nil then
      clear_preview()
      local value, err = require("agents.comments").edit(comment.id, opts.text)
      if not value then
        vim.notify(err, vim.log.levels.WARN)
      end
      return value, err
    end
    require("agents.comment_editor").open(comment.text, save, { on_close = clear_preview })
  end)
end

function M.comment_delete()
  return select_comment(function(comment)
    local value, err = require("agents.comments").delete(comment.id)
    if not value then
      vim.notify(err, vim.log.levels.WARN)
    end
    return value, err
  end)
end

function M.comments_get()
  return require("agents.comments").get()
end
function M.comments_clear()
  return require("agents.comments").clear()
end
function M.comments_format()
  return require("agents.comments").format()
end

--- Edit the review-level note included above all individual comments.
---@param opts? {text?:string}
function M.review_edit(opts)
  opts = opts or {}
  local comments = require("agents.comments")
  if opts.text ~= nil then
    local ok, err = comments.set_review_text(opts.text)
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
      return nil, err
    end
    return opts.text
  end
  require("agents.comment_editor").open(comments.get_review_text(), function(text)
    local ok, err = comments.set_review_text(text)
    return ok, err
  end)
end

---@param opts? {register?:string}
function M.comments_yank(opts)
  opts = opts or {}
  local text = M.comments_format()
  local count = #M.comments_get()
  if count == 0 then
    vim.notify("There are no review comments", vim.log.levels.WARN)
    return nil, "No review comments"
  end
  local register = opts.register or vim.v.register
  if register == '"' then
    register = require("agents.config").review.default_register
  end
  if type(register) ~= "string" or #register ~= 1 or vim.fn.setreg(register, text) ~= 0 then
    vim.notify("Invalid register", vim.log.levels.WARN)
    return nil, "Invalid register"
  end
  vim.notify(string.format("Copied %d review comment%s", count, count == 1 and "" or "s"))
  return text
end

function M.comments_send()
  local text = M.comments_format()
  if #M.comments_get() == 0 then
    vim.notify("There are no review comments", vim.log.levels.WARN)
    return nil, "No review comments"
  end
  local prompt = string.format(require("agents.config").review.submit_prompt, text)
  M.get_proc():send_text(prompt, true)
  return prompt
end

---@param direction integer
local function navigate(direction)
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == "" then
    vim.notify("Navigation requires a file buffer", vim.log.levels.WARN)
    return
  end
  local comment =
    require("agents.comments").navigate(filename, vim.api.nvim_win_get_cursor(0)[1], direction)
  if not comment then
    vim.notify("There are no review comments", vim.log.levels.WARN)
    return
  end
  if vim.fn.bufnr(comment.filename) == -1 and vim.fn.filereadable(comment.filename) ~= 1 then
    vim.notify("Comment file no longer exists: " .. comment.filename, vim.log.levels.WARN)
    return nil, "Comment file no longer exists"
  end
  if vim.fs.normalize(vim.api.nvim_buf_get_name(0)) ~= comment.filename then
    local ok, err = pcall(vim.cmd.edit, vim.fn.fnameescape(comment.filename))
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
      return nil, err
    end
  end
  local lnum = math.min(comment.start_lnum, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd("normal! zvzz")
  return comment
end
function M.comment_next()
  return navigate(1)
end
function M.comment_prev()
  return navigate(-1)
end

return M
