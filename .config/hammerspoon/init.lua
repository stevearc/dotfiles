log = hs.logger.new('stevearc')
log.setLogLevel(5)

function dump(v)
  local ret = hs.inspect.inspect(v)
  log.d(ret)
  return ret
end

sa = hs.alert.show

-- Hot reload config
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")

--Predicate that checks if a window belongs to a screen
function isInScreen(screen, win)
  return win:screen() == screen
end

 -- include minimized/hidden windows, current Space & screen only
local switchers = setmetatable({}, {
  __index = function(t, key)
    local switcher = hs.window.switcher.new(hs.window.filter.new({}):setCurrentSpace(true):setScreens(key):setDefaultFilter({}))
    rawset(t, key, switcher)
    return switcher
  end
})

hs.hotkey.bind('cmd','`',function()
  local curwin = hs.window.focusedWindow()
  local screen = curwin:screen()
  local wins = hs.fnutils.filter(
      hs.window.orderedWindows(),
      hs.fnutils.partial(isInScreen, screen))
  local idx
  for i,win in ipairs(wins) do
    if curwin == win then
      idx = i
      break
    end
  end
  idx = (idx % #wins) + 1
  wins[idx]:focus()
  -- TODO switcher wasn't properly iterating windows on the laptop screen
  -- local switcher = switchers[hs.window.focusedWindow():screen():name()]
  -- switcher:next()
end)

hs.hotkey.bind('cmd-shift','`',function()
  local curwin = hs.window.focusedWindow()
  local screen = curwin:screen()
  local wins = hs.fnutils.filter(
      hs.window.orderedWindows(),
      hs.fnutils.partial(isInScreen, screen))
  local idx
  for i,win in ipairs(wins) do
    if curwin == win then
      idx = i
      break
    end
  end
  idx = idx - 1
  if idx == 0 then
    idx = #wins
  end
  wins[idx]:focus()

  -- local switcher = switchers[hs.window.focusedWindow():screen():name()]
  -- switcher:previous()
end)

function focusScreen(screen)
  --Get windows within screen, ordered from front to back.
  --If no windows exist, bring focus to desktop. Otherwise, set focus on
  --front-most application window.
  local windows = hs.fnutils.filter(
      hs.window.orderedWindows(),
      hs.fnutils.partial(isInScreen, screen))
  
  local windowToFocus = #windows > 0 and windows[1] or hs.window.desktop()
  windowToFocus:focus()

  -- Move mouse to center of screen
  local pt = hs.geometry.rectMidPoint(screen:fullFrame())
  hs.mouse.absolutePosition(pt)
end

hs.hotkey.bind({'cmd', 'shift'}, 'd', function()
  log.i("Debug")
end)

hs.hotkey.bind({'cmd', 'shift'}, 'c', function()
  hs.toggleConsole()
end)


hs.hotkey.bind({'cmd'}, 'h', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  focusScreen(screen:previous())
end)

hs.hotkey.bind({'cmd'}, 'l', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  focusScreen(screen:next())
end)

hs.hotkey.bind({'cmd', 'ctrl'}, 'h', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  win:move(win:frame():toUnitRect(screen:frame()), screen:previous(), true, 0)
end)

hs.hotkey.bind({'cmd', 'ctrl'}, 'l', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end)

hs.hotkey.bind({"cmd"}, "Left", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

hs.hotkey.bind({"cmd"}, "Right", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2)
  f.y = max.y
  f.w = max.w / 2
  f.h = max.h
  win:setFrame(f)
end)

hs.hotkey.bind({"cmd"}, "Return", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x
  f.y = max.y
  f.w = max.w
  f.h = max.h
  win:setFrame(f)
end)
