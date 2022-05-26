local config = require("qf_helper.config")
local aug = vim.api.nvim_create_augroup("StevearcDiagnosticConfig", {})

local function set_loclist_win_height(bufnr, winid, loclist_winid)
  local total = vim.tbl_count(vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.W } }))
  local height = math.max(config.l.min_height, math.min(config.l.max_height, total))
  if loclist_winid ~= 0 and winid ~= loclist_winid then
    if total == 0 then
      vim.api.nvim_win_close(loclist_winid, true)
    else
      -- I don't know why we have to defer here, but BAD THINGS happen if we
      -- don't
      vim.defer_fn(function()
        vim.api.nvim_win_set_height(loclist_winid, height)
      end, 10)
    end
  end
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  desc = "Set diagnostics into the loclist",
  pattern = "*",
  callback = function(params)
    local bufnr = params.buf

    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(winid) then
        local loclist_winid = vim.fn.getloclist(winid, { winid = 1 }).winid
        if vim.api.nvim_win_get_buf(winid) == bufnr then
          vim.diagnostic.setloclist({
            open = false,
            winnr = winid,
            severity = {
              min = vim.diagnostic.severity.W,
            },
          })
        end

        set_loclist_win_height(bufnr, winid, loclist_winid)
      end
    end
  end,
  group = aug,
})

vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Set diagnostics on enter buffer",
  pattern = "*",
  callback = function()
    local bufnr = 0
    local winid = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist({
      open = false,
      winnr = winid,
      severity = {
        min = vim.diagnostic.severity.W,
      },
    })
    local loclist_winid = vim.fn.getloclist(0, { winid = 0 }).winid
    set_loclist_win_height(bufnr, winid, loclist_winid)
  end,
  group = aug,
})
