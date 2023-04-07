local sourced = {}

vim.api.nvim_create_autocmd("DirChanged", {
  desc = "Source .nvim.lua on cd",
  group = "StevearcNewConfig",
  callback = function(args)
    local files = vim.fs.find(".nvim.lua", {
      upward = true,
      path = args.file,
      limit = math.huge,
    })
    for _, file in ipairs(files) do
      if not sourced[file] then
        local source = vim.secure.read(file)
        if source then
          loadstring(source)()
          sourced[file] = true
        end
      end
    end
  end,
})
