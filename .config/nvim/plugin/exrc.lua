local sourced = {}

vim.api.nvim_create_autocmd("DirChanged", {
  desc = "Source .nvim.lua on cd",
  group = "StevearcNewConfig",
  callback = function(args)
    local unsource = {}
    for file in pairs(sourced) do
      if args.file:sub(1, file:len()) ~= file then
        table.insert(unsource, file)
      end
    end
    for _, file in ipairs(unsource) do
      local mod = sourced[file]
      if type(mod) == "table" and mod.deactivate then
        mod.deactivate()
        sourced[file] = nil
      end
    end

    local files = vim.fs.find(".nvim.lua", {
      upward = true,
      path = args.file,
      limit = math.huge,
    })
    for _, file in ipairs(files) do
      if not sourced[file] then
        local source = vim.secure.read(file)
        if source then
          sourced[file] = loadstring(source)() or {}
        end
      end
    end
  end,
})
