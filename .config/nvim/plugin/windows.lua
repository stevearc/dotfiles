vim.o.winwidth = 1
vim.o.winheight = 1
vim.o.splitbelow = true
vim.o.splitright = true

vim.g.win_equal_size = true

local config = {
  winwidth = function(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    return math.max(vim.api.nvim_buf_get_option(bufnr, "textwidth"), 80)
  end,
  winheight = 10,
}

local function set_winlayout_data(layout)
  local type = layout[1]
  if type == "leaf" then
    local winid = layout[2]
    local winfixwidth = vim.api.nvim_win_get_option(winid, "winfixwidth")
    local winfixheight = vim.api.nvim_win_get_option(winid, "winfixheight")
    local min_width = winfixwidth and vim.api.nvim_win_get_width(winid) or 0
    local min_height = winfixheight and vim.api.nvim_win_get_height(winid) or 0
    if vim.api.nvim_get_current_win() == winid then
      if not winfixwidth then
        min_width = config.winwidth(winid)
      end
      if not winfixheight then
        min_height = config.winheight
      end
    end
    layout[2] = {
      winid = winid,
      min_width = min_width,
      min_height = min_height,
      winfixwidth = winfixwidth,
      winfixheight = winfixheight,
      width = min_width,
      height = min_height,
    }
  else
    local winfixwidth = false
    local winfixheight = false
    local min_width = 0
    local min_height = 0
    local width = 0
    local height = 0
    for _, v in ipairs(layout[2]) do
      set_winlayout_data(v)
      winfixwidth = winfixwidth or v[2].winfixwidth
      winfixheight = winfixheight or v[2].winfixheight
      min_width = min_width + v[2].min_width
      min_height = min_height + v[2].min_height
      width = width + v[2].width
      height = height + v[2].height
    end
    layout[2].winfixwidth = winfixwidth
    layout[2].winfixheight = winfixheight
    layout[2].min_width = min_width
    layout[2].min_height = min_height
    layout[2].width = width
    layout[2].height = height
  end
end

local function tbl_count(tbl, fn)
  local count = 0
  for _, v in ipairs(tbl) do
    if fn(v) then
      count = count + 1
    end
  end
  return count
end

local function balance(sections, extra, key)
  local min_val
  local second_min
  local min_count = 0
  for i, v in ipairs(sections) do
    local dim = v[2][key]
    if not min_val or dim < min_val then
      second_min = min_val
      min_val = dim
      min_count = 1
    elseif dim == min_val then
      min_count = min_count + 1
    elseif not second_min or dim < second_min then
      second_min = dim
    end
  end
  local total_boost = extra
  if second_min then
    total_boost = math.min(extra, second_min - min_val)
  end
  local boost = math.floor(total_boost / min_count)
  local mod = total_boost % min_count
  for _, v in ipairs(sections) do
    if v[2][key] == min_val then
      v[2][key] = v[2][key] + boost
      extra = extra - boost
      if mod > 0 then
        mod = mod - 1
        v[2][key] = v[2][key] + 1
        extra = extra - 1
      end
    end
  end
  if extra > 0 then
    balance(sections, extra, key)
  end
end

local function set_dimensions(layout)
  local type = layout[1]
  if type == "leaf" then
    local info = layout[2]
    if vim.api.nvim_win_is_valid(info.winid) then
      vim.api.nvim_win_set_width(info.winid, info.width)
      vim.api.nvim_win_set_height(info.winid, info.height)
    end
  else
    local sections = layout[2]
    if type == "row" then
      -- Adjust the width for the split borders
      sections.width = sections.width - (#sections - 1)
      local flex = {}
      for _, v in ipairs(sections) do
        if not v[2].winfixwidth then
          table.insert(flex, v)
        end
      end
      local remainder = sections.width - sections.min_width
      balance(flex, remainder, "width")
      for _, v in ipairs(sections) do
        v[2].height = sections.height
        set_dimensions(v)
      end
    else
      -- Adjust the height for the split borders
      sections.height = sections.height - (#sections - 1)
      local flex = {}
      for _, v in ipairs(sections) do
        if not v[2].winfixheight then
          table.insert(flex, v)
        end
      end
      local remainder = sections.height - sections.min_height
      balance(flex, remainder, "height")
      for _, v in ipairs(sections) do
        v[2].width = sections.width
        set_dimensions(v)
      end
    end
  end
end

local function resize_windows()
  if not vim.g.win_equal_size then
    return
  end
  local layout = vim.fn.winlayout()
  set_winlayout_data(layout)
  layout[2].width = vim.o.columns
  layout[2].height = vim.o.lines - vim.o.cmdheight - 1 -- The 1 is for the statusline
  set_dimensions(layout)
end

local aug = vim.api.nvim_create_augroup("StevearcWinWidth", {})

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter", "VimResized" }, {
  desc = "Make all windows equal size when switching window",
  pattern = "*",
  callback = resize_windows,
  group = aug,
})

vim.keymap.set("n", "<C-w>+", function()
  vim.g.win_equal_size = not vim.g.win_equal_size
  if vim.g.win_equal_size then
    vim.notify("Window resizing ENABLED")
  else
    vim.notify("Window resizing DISABLED")
  end
end, {})
vim.keymap.set("n", "<C-w>z", "<cmd>resize | vertical resize<CR>", {})
