-- Usage:
-- local profile = require'profile'
-- profile.start('*')
-- <do things>
-- profile.stop('profile.json')

local autocmd = require("profile.autocmd")
local clock = require("profile.clock")
local instrument = require("profile.instrument")
local util = require("profile.util")
local M = {}

local event_defaults = {
  pid = 1,
  tid = 1,
}

-- Call this at the top of your init.vim to get durations for autocmds. If you
-- don't, autocmds will show up as 'instant' events in the profile
M.instrument_autocmds = function()
  autocmd.instrument_start()
end

M.instrument = function(name)
  instrument(name)
end

M.ignore = function(name)
  instrument.ignore(name)
end

M.start = function(...)
  for _, pattern in ipairs({ ... }) do
    instrument(pattern)
  end
  autocmd.instrument_auto()
  instrument.clear_events()
  clock.reset()
  instrument.recording = true
end

M.is_recording = function()
  return instrument.recording
end

M.stop = function(filename)
  instrument.recording = false
  if filename then
    M.export(filename)
  end
end

M.log_start = function(name, ...)
  if not instrument.recording then
    return
  end
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = "function,manual",
    ph = "B",
    ts = clock(),
  })
end

M.log_end = function(name, ...)
  if not instrument.recording then
    return
  end
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = "function,manual",
    ph = "E",
    ts = clock(),
  })
end

M.log_instant = function(name, ...)
  if not instrument.recording then
    return
  end
  instrument.add_event({
    name = name,
    args = util.format_args(...),
    cat = "",
    ph = "i",
    ts = clock(),
    s = "g",
  })
end

M.print_instrumented_modules = function()
  instrument.print_modules()
end

M.export = function(filename)
  local file = io.open(filename, "w")
  local events = instrument.get_events()
  file:write("[")
  for i, event in ipairs(events) do
    local e = vim.tbl_extend("keep", event, event_defaults)
    local ok, jse = pcall(vim.fn.json_encode, e)
    if not ok then
      e.args = nil
      ok, jse = pcall(vim.fn.json_encode, e)
    end
    if ok then
      file:write(jse)
      if i < #events then
        file:write(",\n")
      end
    else
      local err = string.format("Could not encode event: %s\n%s", jse, vim.inspect(e))
      vim.api.nvim_echo({ { err, "Error" } }, true, {})
    end
  end
  file:write("]")
  file:close()
end

return M
