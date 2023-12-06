local config = require("openai.config")
local log = require("openai.log")
local schema = require("openai.schema")
local util = require("openai.util")
local yaml = require("openai.yaml")

local chat_query = [[
(atx_heading
  (atx_h1_marker)
  heading_content: (_) @role
  )

(section
  [(paragraph) (fenced_code_block) (list)] @text
  )
]]

---@param bufnr integer
---@return table
local function parse_settings(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  local yaml_tree = parser:children().yaml
  if not yaml_tree then
    return {}
  end

  local metadata_root = nil
  local trees = yaml_tree:parse()
  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root:start() <= 1 then
      metadata_root = root
    end
  end
  if not metadata_root then
    return {}
  end
  return yaml.decode_node(bufnr, metadata_root) or {}
end

---@param bufnr integer
---@return table
---@return openai.ChatMessage[]
local function parse_messages_buffer(bufnr)
  local ret = {}
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  local query = vim.treesitter.query.parse("markdown", chat_query)
  local root = parser:parse()[1]:root()
  pcall(vim.tbl_add_reverse_lookup, query.captures)
  local message = {}
  for _, match in query:iter_matches(root, bufnr) do
    if match[query.captures.role] then
      if not vim.tbl_isempty(message) then
        table.insert(ret, message)
        message = { role = "", content = "" }
      end
      message.role =
        vim.trim(vim.treesitter.get_node_text(match[query.captures.role], bufnr):lower())
    elseif match[query.captures.text] then
      local text = vim.trim(vim.treesitter.get_node_text(match[query.captures.text], bufnr))
      if message.content then
        message.content = message.content .. "\n\n" .. text
      else
        message.content = text
      end
      -- If there's no role because they just started typing in a blank file, assign the user role
      if not message.role then
        message.role = "user"
      end
    end
  end
  if not vim.tbl_isempty(message) then
    table.insert(ret, message)
  end
  return parse_settings(bufnr), ret
end

---@param bufnr integer
---@param settings openai.ChatCompletionSettings
---@param messages openai.ChatMessage[]
local function render_messages(bufnr, settings, messages)
  local lines = { "---" }
  local keys = schema.get_ordered_keys(schema.static.chat_completion_settings)
  for _, key in ipairs(keys) do
    table.insert(lines, string.format("%s: %s", key, yaml.encode(settings[key])))
  end

  table.insert(lines, "---")
  table.insert(lines, "")

  for i, message in ipairs(messages) do
    if i > 1 then
      table.insert(lines, "")
    end
    table.insert(lines, string.format("# %s", message.role))
    table.insert(lines, "")
    for _, text in ipairs(vim.split(message.content, "\n", { plain = true, trimempty = true })) do
      table.insert(lines, text)
    end
  end
  local modifiable = vim.bo[bufnr].modifiable
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].modifiable = modifiable
end

---@type table<integer, openai.Chat>
local chatmap = {}

local cursor_moved_autocmd
local function watch_cursor()
  if cursor_moved_autocmd then
    return
  end
  cursor_moved_autocmd = vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
    desc = "Show line information in OpenAI buffer",
    callback = function(args)
      local chat = chatmap[args.buf]
      if chat then
        if vim.api.nvim_win_get_buf(0) == args.buf then
          chat:on_cursor_moved()
        end
      end
    end,
  })
end

local registered_cmp = false

---@class openai.Chat
---@field client openai.Client
---@field bufnr integer
---@field settings openai.ChatCompletionSettings
local Chat = {}

---@class openai.ChatArgs
---@field client openai.Client
---@field messages nil|openai.ChatMessage[]
---@field settings nil|openai.ChatCompletionSettings

---@param args openai.ChatArgs
function Chat.new(args)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, string.format("openai-chat://%d", math.random(10000000)))
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].buftype = "acwrite"
  vim.b[bufnr].openai_type = "chat_completion"

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      local chat = chatmap[bufnr]
      if not chat then
        vim.notify("Chat session has been deleted", vim.log.levels.ERROR)
      else
        chat:submit()
      end
    end,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = bufnr,
    callback = function()
      local settings = parse_settings(bufnr)
      local errors = schema.validate(schema.static.chat_completion_settings, settings)
      local node = settings.__ts_node
      local items = {}
      if errors and node then
        for child in node:iter_children() do
          assert(child:type() == "block_mapping_pair")
          local key = vim.treesitter.get_node_text(child:named_child(0), bufnr)
          if errors[key] then
            local lnum, col, end_lnum, end_col = child:range()
            table.insert(items, {
              lnum = lnum,
              col = col,
              end_lnum = end_lnum,
              end_col = end_col,
              severity = vim.diagnostic.severity.ERROR,
              message = errors[key],
            })
          end
        end
      end
      vim.diagnostic.set(config.ERROR_NS, bufnr, items)
    end,
  })
  watch_cursor()

  local bufenter_autocmd
  bufenter_autocmd = vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(params)
      if params.buf ~= bufnr then
        return
      end

      local has_cmp, cmp = pcall(require, "cmp")
      if has_cmp then
        if not registered_cmp then
          require("cmp").register_source("openai", require("cmp_openai").new())
          registered_cmp = true
        end
        cmp.setup.buffer({
          enabled = true,
          sources = {
            { name = "openai" },
          },
        })
      end
      vim.api.nvim_del_autocmd(bufenter_autocmd)
    end,
  })

  local settings = schema.get_default(schema.static.chat_completion_settings, args.settings)

  local self = setmetatable({
    client = args.client,
    bufnr = bufnr,
    settings = settings,
  }, { __index = Chat })
  chatmap[bufnr] = self
  render_messages(bufnr, settings, args.messages or {})
  return self
end

function Chat:submit()
  local settings, messages = parse_messages_buffer(self.bufnr)
  vim.bo[self.bufnr].modified = false
  vim.bo[self.bufnr].modifiable = false
  local function finalize()
    vim.bo[self.bufnr].modified = false
    vim.bo[self.bufnr].modifiable = true
  end
  local new_message = messages[#messages]
  self.client:stream_chat_completion(
    vim.tbl_extend("keep", settings, {
      messages = messages,
    }),
    function(err, chunk, done)
      if err then
        vim.notify("Error: " .. err, vim.log.levels.ERROR)
        return finalize()
      end
      if chunk then
        log:debug("chat chunk: %s", chunk)
        local delta = chunk.choices[1].delta
        if delta.role and delta.role ~= new_message.role then
          new_message = { role = delta.role, content = "" }
          table.insert(messages, new_message)
        end
        if delta.content then
          new_message.content = new_message.content .. delta.content
        end
        render_messages(self.bufnr, settings, messages)
        util.buf_scroll_to_end(self.bufnr)
      end
      if done then
        table.insert(messages, { role = "user", content = "" })
        render_messages(self.bufnr, settings, messages)
        util.buf_scroll_to_end(self.bufnr)
        finalize()
      end
    end
  )
end

---@param opts nil|table
---@return nil|string
---@return nil|TSNode
function Chat:_get_settings_key(opts)
  opts = vim.tbl_extend("force", opts or {}, {
    ignore_injections = false,
  })
  local node = vim.treesitter.get_node(opts)
  while node and node:type() ~= "block_mapping_pair" do
    node = node:parent()
  end
  if not node then
    return
  end
  local key_node = node:named_child(0)
  local key_name = vim.treesitter.get_node_text(key_node, self.bufnr)
  return key_name, node
end

function Chat:on_cursor_moved()
  local key_name, node = self:_get_settings_key()
  if not key_name or not node then
    vim.diagnostic.set(config.INFO_NS, self.bufnr, {})
    return
  end
  local key_schema = schema.static.chat_completion_settings[key_name]

  if key_schema and key_schema.desc then
    local lnum, col, end_lnum, end_col = node:range()
    local diagnostic = {
      lnum = lnum,
      col = col,
      end_lnum = end_lnum,
      end_col = end_col,
      severity = vim.diagnostic.severity.INFO,
      message = key_schema.desc,
    }
    vim.diagnostic.set(config.INFO_NS, self.bufnr, { diagnostic })
  else
    vim.diagnostic.set(config.INFO_NS, self.bufnr, {})
  end
end

function Chat:complete(request, callback)
  local items = {}
  local cursor = vim.api.nvim_win_get_cursor(0)
  local key_name, node = self:_get_settings_key({ pos = { cursor[1] - 1, 1 } })
  if not key_name or not node then
    callback({ items = items, isIncomplete = false })
    return
  end

  local key_schema = schema.static.chat_completion_settings[key_name]
  if key_schema.type == "enum" then
    for _, choice in ipairs(key_schema.choices) do
      table.insert(items, {
        label = choice,
        kind = require("cmp").lsp.CompletionItemKind.Keyword,
      })
    end
  end

  callback({ items = items, isIncomplete = false })
end

---@param bufnr nil|integer
---@return nil|openai.Chat
function Chat.buf_get_chat(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return chatmap[bufnr]
end

return Chat
