local Client = require("openai.client")
local util = require("openai.util")
local M = {}

local _client
---@return nil|openai.Client
local function get_client()
  if not _client then
    local secret_key = os.getenv("OPENAI_API_KEY")
    if not secret_key then
      vim.notify("Could not find env variable: OPENAI_API_KEY", vim.log.levels.ERROR)
      return nil
    end
    _client = Client.new({
      secret_key = secret_key,
      organization = os.getenv("OPENAI_ORG"),
    })
  end
  return _client
end

---@param bufnr nil|integer
---@return nil|openai.Chat
M.buf_get_chat = function(bufnr)
  return require("openai.chat").buf_get_chat(bufnr)
end

M.open = function()
  local client = get_client()
  if not client then
    return
  end
  local Chat = require("openai.chat")
  local chat = Chat.new({
    client = client,
  })
  vim.api.nvim_win_set_buf(0, chat.bufnr)
  util.scroll_to_end(0)
  vim.bo[chat.bufnr].filetype = "markdown"
end

local last_edit
---@param line1 integer
---@param line2 integer
M.edit_text = function(line1, line2)
  local client = get_client()
  if not client then
    return
  end
  local ChatEdit = require("openai.edit")
  last_edit = ChatEdit.new({
    line1 = line1,
    line2 = line2,
    client = client,
  })
  last_edit:start(function()
    util.set_dot_repeat("repeat_last_edit")
  end)
end

M.repeat_last_edit = function()
  if last_edit and vim.api.nvim_get_current_buf() == last_edit.bufnr then
    last_edit:start(function()
      util.set_dot_repeat("repeat_last_edit")
    end)
  end
end

M.setup = function()
  vim.api.nvim_create_user_command("AIChat", function()
    M.open()
  end, { desc = "" })
  vim.api.nvim_create_user_command("AIEdit", function(args)
    M.edit_text(args.line1, args.line2)
  end, {
    desc = "",
    range = true,
  })
  -- TODO
  -- * edit-like flow using chat chaining
  -- * annotation tool for diagnostics
  require("openai.config").setup()
end

return M
