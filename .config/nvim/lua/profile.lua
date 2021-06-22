-- WIP super unfinished. Right now it can only do simple printing.
local M = {}

local function is_path_pattern(pattern)
  return string.find(pattern, '.', string.len(pattern) - 1, true)
end

local function pass_override(name, overrides)
  return not overrides or overrides[name] ~= false
end

local function pathmatch(haystack, pattern, overrides)
  if not pass_override(haystack, overrides) then
    return false
  end
  if is_path_pattern(pattern) then
    return 1 == string.find(haystack, pattern, 1, true)
  else
    return haystack == pattern
  end
end

local function wrap_module(name, overrides)
  if not pass_override(name, overrides) then
    return
  end
  local ok, mod = pcall(require, name)
  if ok and mod then
    for k,v in pairs(mod) do
      if type(v) == 'function' then
        local fnname = string.format("%s.%s", name, k)
        if pass_override(fnname, overrides) then
          mod[k] = M.wrap(fnname, v)
        end
      end
    end
  end
end

local mt = {
  __call = function(self, name_or_module, fn)
    local clock = self.get_clock()
    local ret = fn()
    clock.print(name_or_module)
    return ret
  end
}

M.wrap = function(name, fn)
  return function(...)
    local clock = M.get_clock()
    local ret = fn(...)
    clock.print(name)
    return ret
  end
end

M.module = function(name, overrides)
  if is_path_pattern(name) then
    wrap_module(string.sub(name, 1, string.len(name) - 1))
    for mod in pairs(package.loaded) do
      if pathmatch(mod, name) then
        wrap_module(mod, overrides)
      end
    end
  else
    wrap_module(name, overrides)
  end
end

M.get_clock = function()
  local start = vim.loop.hrtime()
  local times = {}
  local function get_time()
    return (vim.loop.hrtime() - start)/1e6
  end
  return setmetatable({
    record = function(name)
      times[name] = get_time()
    end,

    print = function(name)
      local t = get_time()
      vim.defer_fn(function()
        print(string.format("%s %f", name, t))
      end, 10)
    end,
  }, {
  __call = get_time,
  })
end

return setmetatable(M, mt)
