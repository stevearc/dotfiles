local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local Spacer = { provider = " " }
local function rpad(child)
  return {
    condition = child.condition,
    child,
    Spacer,
  }
end
local function lpad(child)
  return {
    condition = child.condition,
    Spacer,
    child,
  }
end

local stl_static = {
  mode_color_map = {
    n = "function",
    i = "green",
    v = "statement",
    V = "statement",
    ["\22"] = "statement",
    c = "yellow",
    s = "statement",
    S = "statement",
    ["\19"] = "statement",
    R = "red",
    r = "red",
    ["!"] = "constant",
    t = "constant",
  },
  mode_color = function(self)
    local mode = vim.fn.mode(1):sub(1, 1) -- get only the first mode character
    return self.mode_color_map[mode]
  end,
}

local ViMode = {
  init = function(self)
    self.mode = vim.fn.mode(1) -- :h mode()

    -- execute this only once, this is required if you want the ViMode
    -- component to be updated on operator pending mode
    if not self.once then
      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*:*o",
        command = "redrawstatus",
      })
      self.once = true
    end
  end,
  -- Now we define some dictionaries to map the output of mode() to the
  -- corresponding string and color. We can put these into `static` to compute
  -- them at initialisation time.
  static = {
    mode_names = {
      n = "NORMAL",
      no = "NORMAL-",
      nov = "NORMAL-",
      noV = "NORMAL-",
      ["no\22"] = "NORMAL-",
      niI = "NORMAL-",
      niR = "NORMAL-",
      niV = "NORMAL-",
      nt = "NORMAL-",
      v = "VISUAL",
      vs = "VISUAL-",
      V = "V-LINE",
      Vs = "V-LINE-",
      ["\22"] = "V-BLOCK",
      ["\22s"] = "V-BLOCK-",
      s = "SELECT",
      S = "S-LINE",
      ["\19"] = "S-BLOCK",
      i = "INSERT",
      ic = "INSERT-",
      ix = "INSERT-",
      R = "REPLACE",
      Rc = "REPLACE-",
      Rx = "REPLACE-",
      Rv = "REPLACE-",
      Rvc = "REPLACE-",
      Rvx = "REPLACE-",
      c = "COMMAND",
      cv = "COMMAND-",
      r = "PROMPT",
      rm = "MORE",
      ["r?"] = "CONFIRM",
      ["!"] = "SHELL",
      t = "TERMINAL",
    },
  },
  provider = function(self) return " " .. self.mode_names[self.mode] .. " " end,
  hl = function(self) return { fg = "black", bg = self:mode_color(), bold = true } end,
  update = {
    "ModeChanged",
  },
}

local FileIcon = {
  init = function(self)
    self.icon, self.icon_color =
      require("nvim-web-devicons").get_icon_color_by_filetype(vim.bo.filetype, { default = true })
  end,
  provider = function(self) return self.icon and (self.icon .. " ") end,
  hl = function(self) return { fg = self.icon_color } end,
}

local FileType = {
  condition = function() return vim.bo.filetype ~= "" end,
  FileIcon,
  {
    provider = function() return vim.bo.filetype end,
  },
}

local FileName = {
  provider = function(self)
    local filename
    if package.loaded.oil then
      filename = require("oil").get_current_dir()
    end
    if not filename then
      filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
    end
    if filename == "" then
      return "[No Name]"
    end
    -- now, if the filename would occupy more than 90% of the available
    -- space, we trim the file path to its initials
    if not conditions.width_percent_below(#filename, 0.90) then
      filename = vim.fn.pathshorten(filename)
    end
    return filename
  end,
}

local FileFlags = {
  {
    condition = function() return vim.bo.modified end,
    provider = " [+]",
  },
  {
    condition = function() return not vim.bo.modifiable or vim.bo.readonly end,
    provider = " ",
  },
}

local FullFileName = {
  hl = function()
    local fg
    if vim.bo.modified then
      fg = "yellow"
    else
      -- fg = conditions.is_active() and "tablinesel_fg" or "tabline_fg"
      fg = "tabline_fg"
    end
    return {
      fg = fg,
      -- bg = conditions.is_active() and "tablinesel_bg" or "winbar_bg",
      bg = "winbar_bg",
    }
  end,
  FileName,
  FileFlags,
  { provider = "%=" },
}

local function OverseerTasksForStatus(status)
  return {
    condition = function(self) return self.tasks[status] end,
    provider = function(self) return string.format("%s%d", self.symbols[status], #self.tasks[status]) end,
    hl = function(self)
      return {
        fg = utils.get_highlight(string.format("Overseer%s", status)).fg,
      }
    end,
  }
end
local Overseer = {
  condition = function() return package.loaded.overseer end,
  init = function(self)
    local tasks = require("overseer.task_list").list_tasks({ unique = true })
    local tasks_by_status = require("overseer.util").tbl_group_by(tasks, "status")
    self.tasks = tasks_by_status
  end,
  static = {
    symbols = {
      ["CANCELED"] = " ",
      ["FAILURE"] = "󰅚 ",
      ["SUCCESS"] = "󰄴 ",
      ["RUNNING"] = "󰑮 ",
    },
  },

  rpad(OverseerTasksForStatus("CANCELED")),
  rpad(OverseerTasksForStatus("RUNNING")),
  rpad(OverseerTasksForStatus("SUCCESS")),
  rpad(OverseerTasksForStatus("FAILURE")),
}

local Gutentags = {
  condition = function() return vim.fn.exists("*gutentags#statusline") == 1 end,
  provider = function(self) return vim.fn["gutentags#statusline"](" ") end,
}

local Diagnostics = {
  condition = function() return #vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.WARN } }) > 0 end,
  static = {
    error_icon = vim.g.nerd_font and "󰅚 " or "E",
    warn_icon = vim.g.nerd_font and "󰀪 " or "W",
  },
  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  end,
  update = { "DiagnosticChanged", "BufEnter" },

  {
    provider = function(self) return self.errors > 0 and (self.error_icon .. self.errors .. " ") end,
    hl = { fg = "diag_error" },
  },
  {
    provider = function(self) return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ") end,
    hl = { fg = "diag_warn" },
  },
}

local function setup_colors()
  return {
    fg = utils.get_highlight("StatusLine").fg or "none",
    bg = utils.get_highlight("StatusLine").bg or "none",
    winbar_fg = utils.get_highlight("WinBar").fg or "none",
    winbar_bg = utils.get_highlight("WinBar").bg or "none",
    tablinesel_fg = utils.get_highlight("TabLineSel").fg or "none",
    tablinesel_bg = utils.get_highlight("TabLineSel").bg or "none",
    tabline_fg = utils.get_highlight("TabLine").fg or "none",
    red = utils.get_highlight("DiagnosticError").fg or "none",
    yellow = utils.get_highlight("DiagnosticWarn").fg or "none",
    green = utils.get_highlight("DiagnosticOk").fg or "none",
    gray = utils.get_highlight("NonText").fg or "none",
    ["function"] = utils.get_highlight("Function").fg or "none",
    constant = utils.get_highlight("Constant").fg or "none",
    statement = utils.get_highlight("Statement").fg or "none",
    visual = utils.get_highlight("Visual").bg or "none",
    diag_warn = utils.get_highlight("DiagnosticWarn").fg or "none",
    diag_error = utils.get_highlight("DiagnosticError").fg or "none",
  }
end

local SessionName = {
  condition = function() return package.loaded.resession and require("resession").get_current() end,
  provider = function() return string.format("󰆓 %s", require("resession").get_current()) end,
}

local ArduinoStatus = {
  condition = function() return vim.bo.filetype == "arduino" end,
  provider = function()
    local port = vim.fn["arduino#GetPort"]()
    local line = string.format("[%s]", vim.g.arduino_board)
    if vim.g.arduino_programmer ~= "" then
      line = line .. string.format(" [%s]", vim.g.arduino_programmer)
    end
    if port ~= 0 then
      line = line .. string.format(" (%s:%s)", port, vim.g.arduino_serial_baud)
    end
    return line
  end,
}

-- HACK I don't know why, but the stock implementation of lsp_attached is causing error output
-- (UNKNOWN PLUGIN): Error executing lua: attempt to call a nil value
-- It gets written to raw stderr, which then messes up all of vim's rendering. It's something to do
-- with the require("vim.lsp") call deep in the vim metatable __index function. I don't know the
-- root cause, but I'm done debugging this for today.
conditions.lsp_attached = function()
  local lsp = rawget(vim, "lsp")
  if not lsp then
    return false
  elseif lsp.get_clients then
    return next(lsp.get_clients({ bufnr = 0 })) ~= nil
  else
    return next(lsp.get_active_clients({ bufnr = 0 })) ~= nil
  end
end

local LSPActive = {
  update = { "LspAttach", "LspDetach", "VimResized", "FileType", "BufEnter", "BufWritePost" },

  flexible = 1,
  {
    provider = function()
      local names = {}
      local lsp = rawget(vim, "lsp")
      if lsp then
        local clients
        if lsp.get_clients then
          clients = lsp.get_clients({ bufnr = 0 })
        else
          clients = lsp.get_active_clients({ bufnr = 0 })
        end
        for _, server in pairs(clients) do
          table.insert(names, server.name)
        end
      end
      local lint = package.loaded.lint
      if lint and vim.bo.buftype == "" then
        table.insert(names, "⫽")
        for _, linter in ipairs(lint.linters_by_ft[vim.bo.filetype] or {}) do
          table.insert(names, linter)
        end
      end
      local conform = package.loaded.conform
      if conform and vim.bo.buftype == "" then
        local formatters, format_with_lsp = conform.list_formatters_to_run(0)
        if format_with_lsp or not vim.tbl_isempty(formatters) then
          table.insert(names, "⫽")
          for _, formatter in ipairs(formatters) do
            table.insert(names, formatter.name)
          end
          if format_with_lsp then
            table.insert(names, "LSP")
          end
        end
      end
      if vim.tbl_isempty(names) then
        return ""
      else
        return " [" .. table.concat(names, " ") .. "]"
      end
    end,
  },
  {
    condition = conditions.lsp_attached,
    provider = " [LSP]",
  },
  {
    condition = conditions.lsp_attached,
    provider = " ",
  },
}

local Ruler = {
  provider = " %P %l:%c ",
  hl = function(self) return { fg = "black", bg = self:mode_color(), bold = true } end,
}

local ConjoinStatus = {
  condition = function()
    local ok, state = pcall(require, "conjoin.state")
    return ok and state.id ~= -1
  end,

  flexible = 1,
  {
    provider = function()
      local state = require("conjoin.state")
      local others = state.get_other_users()
      local names = vim.tbl_map(function(u) return u.name end, others)
      return string.format(" [%s]", table.concat(names, ", "))
    end,
  },
  {
    provider = function()
      local state = require("conjoin.state")
      local others = state.get_other_users()
      return string.format(" %d", #others)
    end,
  },
  {
    provider = " ",
  },
}

local ProfileRecording = {
  condition = function()
    local profile = package.loaded.profile
    return profile and profile.is_recording()
  end,
  provider = function() return "󰑊 " end,
  hl = function() return { fg = "red" } end,
  update = {
    "User",
    pattern = { "ProfileStart", "ProfileStop" },
  },
}

local DAPStatus = {
  condition = function() return package.loaded.dap and require("dap").session() ~= nil end,
  provider = function() return " " .. require("dap").status() end,
  hl = "Debug",
  update = {
    "User",
    pattern = "DapProgressUpdate",
  },
}

local ClaudeStatus = {
  condition = function() return vim.t.claude_thinking end,
  provider = function() return " " end,
  hl = "DiagnosticOk",
  update = {
    "User",
    pattern = "ClaudeStatus",
  },
}

return {
  ViMode = ViMode,
  Ruler = Ruler,
  Spacer = Spacer,
  rpad = rpad,
  lpad = lpad,
  FileIcon = FileIcon,
  FileType = FileType,
  FullFileName = FullFileName,
  Gutentags = Gutentags,
  Overseer = Overseer,
  Diagnostics = Diagnostics,
  setup_colors = setup_colors,
  SessionName = SessionName,
  ArduinoStatus = ArduinoStatus,
  LSPActive = LSPActive,
  stl_static = stl_static,
  ConjoinStatus = ConjoinStatus,
  ProfileRecording = ProfileRecording,
  DAPStatus = DAPStatus,
  ClaudeStatus = ClaudeStatus,
}
