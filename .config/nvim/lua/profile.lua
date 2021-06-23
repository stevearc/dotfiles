-- TODO
-- * optionally profile requires on startup
-- * test that it works with multiple return values, some of which are nil
-- * test that it works with multiple parameters, some of which are nil
-- * simple ascii file output
-- * integrate with vim profiling tool?
local autocmd = require'profile.autocmd'
local clock = require'profile.clock'
local instrument = require'profile.instrument'
local util = require'profile.util'
local M = {}

local event_defaults = {
  pid = 1,
  tid = 1,
}

M.instrument = function(name)
  instrument(name)
end

M.ignore = function(name)
  instrument.ignore(name)
end

M.start_recording = function()
  instrument.clear_events()
  autocmd.instrument()
  clock.reset()
  instrument.recording = true
end

M.is_recording = function()
  return instrument.recording
end

M.stop_recording = function()
  instrument.recording = false
  autocmd.clear()
end

M.log_start = function(name, ...)
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = 'function,manual',
    ph = 'B',
    ts = clock(),
  })
end

M.log_end = function(name, ...)
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = 'function,manual',
    ph = 'E',
    ts = clock(),
  })
end

M.log_instant = function(name, ...)
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = '',
    ph = 'i',
    ts = clock(),
    s = 'g',
  })
end

M.export = function(filename)
  local file = io.open(filename, 'w')
  local events = instrument.get_events()
  file:write('[')
  for i,event in ipairs(events) do
    local e = vim.tbl_extend('keep', event, event_defaults)
    local ok, jse = pcall(vim.fn.json_encode, e)
    if ok then
      -- file:write(vim.fn.json_encode(e))
      file:write(jse)
      if i < #events then
        file:write(',\n')
      end
    else
      error(string.format("Could not encode event: %s\n%s", jse, vim.inspect(e)))
      print(string.format("event: %s", e))
    end
  end
  file:write(']')
  file:close()
end

return M
