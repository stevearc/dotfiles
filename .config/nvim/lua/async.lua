local uv = vim.uv or vim.loop

local M = {}

local function create_async_handle(callback)
  local async
  async = uv.new_async(vim.schedule_wrap(function(ret)
    callback(unpack(vim.mpack.decode(ret)))
    async:close()
  end))
  return async
end

M.run_in_thread = function(callback, fn, ...)
  local handle = create_async_handle(callback)
  uv.new_thread(function(fn_str, async, args_str)
    local args = vim.mpack.decode(args_str)
    local function pack(...)
      return { ... }
    end
    local ret = pack(loadstring(fn_str)(unpack(args)))
    async:send(vim.mpack.encode(ret))
  end, string.dump(fn), handle, vim.mpack.encode({ ... }))
end

return M
