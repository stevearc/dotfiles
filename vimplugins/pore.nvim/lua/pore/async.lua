local M = {}

M.run = function(async_fn, callback, interval, ...)
  interval = interval or 100
  local t = coroutine.create(async_fn)

  local function poll(...)
    local ok, ret = coroutine.resume(t, ...)
    if coroutine.status(t) == "dead" then
      local err = nil
      if not ok then
        err, ret = ret, err
      end
      vim.schedule_wrap(callback)(err, ret)
      return true
    end
    return false
  end

  if not poll(...) then
    local timer = vim.loop.new_timer()
    timer:start(interval, interval, function()
      if poll() then
        timer:close()
      end
    end)
  end
end

return M
