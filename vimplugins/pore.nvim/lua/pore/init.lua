local api = require("pore.api")
local async = require("pore.async")
local M = {}

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
local function path_join(...)
  return table.concat(vim.tbl_flatten({ ... }), path_sep)
end
local package_path = vim.fn.fnamemodify(string.sub(debug.getinfo(1, "S").source, 2), ":p:h:h:h")

M.install_from_source = function()
  if vim.fn.has("win32") == 1 then
    vim.api.nvim_err_writeln("Cannot install from source on windows")
    return
  end
  vim.ui.input({ prompt = "Source dir:", completion = "dir" }, function(dir)
    if not dir then
      return
    end
    dir = vim.fn.expand(dir)
    if vim.fn.isdirectory(dir) == 0 then
      vim.api.nvim_err_writeln(string.format("No such directory %s", dir))
    end
    local out = {}
    local on_output = function(chan_id, output)
      vim.list_extend(out, output)
    end
    vim.fn.jobstart({ "cargo", "build" }, {
      cwd = dir,
      on_stdout = on_output,
      on_stderr = on_output,
      on_exit = function(chan_id, code)
        if code == 0 then
          vim.notify("Pore build succeeded", vim.log.levels.INFO)
          local source = path_join(dir, "target", "debug", "libpore_lua.so")
          local dest = path_join(package_path, "lua", "pore_lua.so")
          if vim.fn.filereadable(dest) ~= 0 then
            vim.fn.delete(dest)
          end
          os.execute(string.format("ln -s %s %s", source, dest))
        else
          vim.notify("Pore build failed. Check :messages for details", vim.log.levels.ERROR)
          vim.api.nvim_err_write(table.concat(out, "\n"))
        end
      end,
    })
  end)
end

M.print_version = function()
  print(vim.inspect(api.version))
end

M.test = function()
  -- local obj = api.get_test_obj()
  -- async.run(obj.test_async, function(err)
  --   print(string.format("Finished call 1 %s", err))
  -- end, 100, obj, "g")
  -- vim.defer_fn(function()
  --   async.run(obj.test_async, function(err)
  --     print(string.format("Finished call 2 %s", err))
  --   end, 100, obj, "g")
  -- end, 1000)

  -- local index = api.get_file_index(vim.loop.cwd(), nil, {})
  -- index:update()
  -- async.run(index.search_async, function(err)
  --   print(string.format("Finished call 1 %s", err))
  -- end, 100, index, "g")
  -- vim.defer_fn(function()
  --   async.run(index.search_async, function(err)
  --     print(string.format("Finished call 2 %s", err))
  --   end, 100, index, "g")
  -- end, 1000)

  local mod = require("pore_lua")
  async.run(mod.test_async, function()
    print("Finished call 1")
  end, 100)
  async.run(mod.test_async, function()
    print("Finished call 2")
  end, 100)
  --
  -- async.run(api.test_async, function(err, val)
  --   if err then
  --     print(string.format("Error: %s", err))
  --   else
  --     print(string.format("Async finished: %s %s", type(val), val))
  --   end
  -- end)
end

return M
