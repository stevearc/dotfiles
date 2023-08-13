---@return string
local function mkdtemp()
  local tmp = assert(vim.loop.os_tmpdir())
  local num = 0
  for _ = 1, 5 do
    num = 10 * num + math.random(0, 9)
  end

  local newdir = string.format("%s/tmp_%d", tmp, num)
  vim.fn.mkdir(newdir, "p")
  return newdir
end

---@param path string
---@return any
local function read_json_file(path)
  local fd = assert(vim.loop.fs_open(path, "r", 420)) -- 0644
  local stat = assert(vim.loop.fs_fstat(fd))
  local content = assert(vim.loop.fs_read(fd, stat.size))
  vim.loop.fs_close(fd)

  return vim.json.decode(content, { luanil = { object = true } })
end

---@param path string
---@param data any
local function write_json_file(path, data)
  local fd = assert(vim.loop.fs_open(path, "w", 420)) -- 0644
  vim.loop.fs_write(fd, vim.json.encode(data))
  vim.loop.fs_close(fd)
end

---@param configpath? string
---@param ignore string[]
---@return table
local function gen_config(configpath, ignore)
  local config
  if configpath then
    config = vim.tbl_deep_extend("force", read_json_file(configpath), {
      Lua = {
        telemetry = {
          enable = false,
        },
      },
    })
  else
    config = {
      Lua = {
        telemetry = {
          enable = false,
        },
        diagnostics = {
          globals = { "it", "describe", "before_each", "after_each" },
        },
        runtime = {
          version = "LuaJIT",
        },
      },
    }
  end
  config.Lua.workspace = config.Lua.workspace or {}
  config.Lua.workspace.library = config.Lua.workspace.library or {}
  table.insert(config.Lua.workspace.library, vim.env.VIMRUNTIME)
  config.Lua.workspace.ignoreDir = config.Lua.workspace.ignoreDir or {}
  vim.list_extend(config.Lua.workspace.ignoreDir, ignore)
  return config
end

local severity_to_string = {
  "INFO",
  "WARN",
  "ERROR",
}

---@param opts Options
---@return integer Exit code
---@return table?
local function typecheck(opts)
  local logdir = mkdtemp()
  local config = gen_config(opts.configpath, opts.ignore)
  local configpath = string.format("%s/luarc.json", logdir)
  write_json_file(configpath, config)
  local cmd = {
    opts.bin or "lua-language-server",
    "--logpath",
    logdir,
    "--configpath",
    configpath,
    "--checklevel",
    opts.level or "Warning",
    "--check",
    opts.path,
  }
  local cmdstr = table.concat(cmd, " ")
  print(cmdstr)
  print("\n")

  local exit_code
  local jid = vim.fn.jobstart(cmd, {
    on_exit = function(j, code)
      exit_code = code
    end,
  })
  if jid == 0 then
    print(string.format("Passed invalid arguments to '%s'", opts.bin))
    return 1
  elseif jid == -1 then
    print(string.format("'%s' is not executable", opts.bin))
    return 1
  end
  vim.fn.jobwait({ jid })

  if exit_code ~= 0 then
    return exit_code
  end

  local logfile = string.format("%s/check.json", logdir)

  if vim.fn.filereadable(logfile) == 0 then
    print(string.format("Could not read '%s'", logfile))
    return 1
  end

  local diagnostics = read_json_file(logfile)

  vim.fn.delete(logdir, "rf")

  -- Remove diagnostics from VIMRUNTIME
  for _, uri in ipairs(vim.tbl_keys(diagnostics)) do
    local filename = string.sub(uri, 8) -- trim off the leading file://
    if vim.startswith(filename, vim.env.VIMRUNTIME) then
      diagnostics[uri] = nil
    end
  end

  return 0, diagnostics
end

local function print_diagnostics(diagnostics)
  local curdir = vim.fn.getcwd()
  local count = 0
  local uris = vim.tbl_keys(diagnostics)
  table.sort(uris)
  for _, uri in ipairs(uris) do
    local filename = string.sub(uri, 8) -- trim off the leading file://
    if vim.startswith(filename, curdir) then
      filename = filename:sub(curdir:len() + 2)
    end
    local file_diagnostics = diagnostics[uri]
    for _, diagnostic in ipairs(file_diagnostics) do
      local severity = severity_to_string[diagnostic.severity]
      local msg = vim.split(diagnostic.message, "\n", { plain = true, trimempty = true })[1]
      local line = string.format(
        "%s %s:%d:%d:%d:%d: %s",
        severity,
        filename,
        diagnostic.range.start.line,
        diagnostic.range.start.character,
        diagnostic.range["end"].line,
        diagnostic.range["end"].character,
        msg
      )
      vim.api.nvim_out_write(line .. "\n")
      count = count + 1
    end
  end
  if count == 0 then
    print("No issues found!")
  else
    print(string.format("Found %d issues", count))
  end
end

---@class Options
---@field path string
---@field bin? string
---@field level? "Error"|"Warning"|"Information"
---@field configpath? string
---@field ignore string[]

---@param path string
---@return string
local function parse_configpath(path)
  if vim.fn.filereadable(path) == 0 then
    print(string.format("Could not find configpath file '%s'", path))
    os.exit(1)
  end
  return vim.fn.fnamemodify(path, ":p")
end

---@param level string
---@return "Error"|"Warning"|"Information"
local function parse_level(level)
  local lower_level = level:lower()
  if lower_level == "error" then
    return "Error"
  elseif lower_level == "warning" then
    return "Warning"
  elseif lower_level == "information" then
    return "Information"
  else
    print(string.format("Level '%s' must be one of Information, Warning, or Error", level))
    os.exit(1)
  end
end

---@param bin string
---@return string
local function parse_bin(bin)
  if vim.fn.filereadable(bin) == 0 then
    print(string.format("Could not find bin file '%s'", bin))
    os.exit(1)
  end
  return bin
end

local function print_help()
  local help = table.concat({
    string.format("%s [OPTIONS] [PATH]", arg[0]),
    "\nOptions:",
    "  -h, --help             Print help and exit",
    "  --bin BIN              Path to lua-language-server",
    "  --level LEVEL          Minimum level to check (one of Information, Warning, Error)",
    "  --configpath CONFIG    Path to luarc.json config file",
    "  --ignore PATH          Path to ignore. May be specified multiple times",
    "",
  }, "\n")
  print(help)
end

---@param cli_args string[]
---@return Options
local function parse_args(cli_args)
  local opts = {
    ignore = {},
  }
  local i = 1
  while i <= #cli_args do
    local str = cli_args[i]
    if str == "-h" or str == "--help" then
      print_help()
      os.exit(0)
    elseif str == "--level" then
      i = i + 1
      opts.level = parse_level(cli_args[i])
    elseif str == "--bin" then
      i = i + 1
      opts.bin = parse_bin(cli_args[i])
    elseif str == "--configpath" then
      i = i + 1
      opts.configpath = parse_configpath(cli_args[i])
    elseif str == "--ignore" then
      i = i + 1
      table.insert(opts.ignore, cli_args[i])
    else
      if opts.path then
        print("Error: can only specify one path to check")
        print_help()
        os.exit(1)
      else
        opts.path = str
      end
    end
    i = i + 1
  end

  opts.path = opts.path or "."
  return opts
end

-- Ensure that the stdout doesn't get truncated
vim.o.columns = 10000
math.randomseed(vim.loop.hrtime())
local opts = parse_args(arg)
local code, diagnostics = typecheck(opts)
if code ~= 0 then
  os.exit(code)
end
print_diagnostics(diagnostics)
code = vim.tbl_isempty(diagnostics) and 0 or 2
os.exit(code)
