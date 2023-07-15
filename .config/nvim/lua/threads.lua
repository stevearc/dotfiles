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

---@param callback fun(...) Function to call when the thread returns
---@param fn fun(...) Function to run in a thread
---@param ... any Arguments to pass to the function
M.run_in_thread = function(callback, fn, ...)
  M.wrap_threaded(fn)(..., callback)
end

---@param fn fun(...: any): any Function to run in a thread
---@return fun(...: any): any Async function that accepts the same arguments except the last argument is a callback function with the return values as parameters
---@example
--- local function sleep_greeter(name)
---   vim.loop.sleep(1000)
---   return "Hello " .. name
--- end
--- local async_sleep_greeter = wrap_threaded(sleep_greeter)
--- async_sleep_greeter("John", function(greeting)
---   print(greeting)
--- end)
M.wrap_threaded = function(fn)
  local str_fun = string.dump(fn)
  return function(...)
    local callback = select(-1, ...)
    local args = { ... }
    -- Remove the callback from args
    args[select("#", ...)] = nil
    local handle = create_async_handle(callback)
    uv.new_thread(function(fn_str, async, args_str)
      local thread_args = vim.mpack.decode(args_str)
      local ret = { loadstring(fn_str)(unpack(thread_args)) }
      async:send(vim.mpack.encode(ret))
    end, str_fun, handle, vim.mpack.encode(args))
  end
end

return M
