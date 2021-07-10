local has_neogit, notification = pcall(require, "neogit.lib.notification")
local M = {}

M.toast = function(message, options)
  options = options or {}
  if not options.delay then
    options.delay = options.type == "error" and 5000 or 3000
    -- Give me a bit more time to read long messages
    options.delay = options.delay + 20 * string.len(message)
  end
  options.type = options.type or "info"
  message = string.gsub(message, "%s*$", "")
  if has_neogit and not string.find(message, "\n") then
    notification.create(message, options)
  else
    if options.type == "info" then
      vim.notify(message, vim.log.levels.INFO)
    elseif options.type == "warning" then
      vim.notify(message, vim.log.levels.WARN)
    else
      vim.notify(message, vim.log.levels.ERROR)
    end
    vim.cmd("redraw")
  end
end

setmetatable(M, {
  __call = function(self, ...)
    self.toast(...)
  end,
})

return M
