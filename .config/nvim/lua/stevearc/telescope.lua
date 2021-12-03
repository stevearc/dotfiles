local M = {}

M.myles_find_files = function()
  require("myles").find_files({
    previewer = false,
  })
end

return M
