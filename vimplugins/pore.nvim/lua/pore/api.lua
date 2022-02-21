local warned = false

return setmetatable({}, {
  __index = function(t, key)
    local ok, mod = pcall(require, "pore_lua")
    if ok then
      -- TODO version check
      for k, v in pairs(mod) do
        t[k] = v
      end
      return t[key]
    end
    if not warned then
      vim.notify("pore-lua not installed. Run :PoreInstall", vim.log.levels.ERROR)
      warned = true
    end
    local dummy = {}
    setmetatable(dummy, {
      __call = function()
        return dummy
      end,
      __index = function()
        return dummy
      end,
    })
    return dummy
  end,
})
