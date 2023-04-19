vim.diagnostic.config({
  float = {
    source = "always",
    border = "rounded",
    severity_sort = true,
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.W },
    source = "if_many",
  },
  severity_sort = true,
})

if vim.g.nerd_font then
  vim.cmd([[
      sign define DiagnosticSignError text=󰅚   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=󰀪  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInfo text=• texthl=DiagnosticSignInfo
      sign define DiagnosticSignHint text=• texthl=DiagnosticSignHint
    ]])
else
  vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInfo text=. texthl=DiagnosticSignInfo
      sign define DiagnosticSignHint text=. texthl=DiagnosticSignHint
    ]])
end

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)

local aug = vim.api.nvim_create_augroup("StevearcDiagnosticConfig", {})

local function set_loclist_win_height(bufnr, winid, loclist_winid)
  local total = vim.tbl_count(vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.W } }))
  if loclist_winid ~= 0 and winid ~= loclist_winid then
    if total == 0 then
      vim.api.nvim_win_close(loclist_winid, true)
    else
      local has_qf_helper, config = pcall(require, "qf_helper.config")
      local height
      if has_qf_helper then
        height = math.max(config.l.min_height, math.min(config.l.max_height, total))
      else
        height = math.max(2, math.min(10, total))
      end
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
  callback = vim.schedule_wrap(function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype == "quickfix" then
      return
    end
    local loclist_data = vim.fn.getloclist(0, { winid = 0 })
    local winid = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist({
      open = false,
      winnr = winid,
      severity = {
        min = vim.diagnostic.severity.W,
      },
    })
    set_loclist_win_height(bufnr, winid, loclist_data.winid)
  end),
  group = aug,
})
