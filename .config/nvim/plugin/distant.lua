safe_require("distant", function(distant)
  local actions = require("distant.nav.actions")

  -- TODO remaining features that I need:
  -- * cd into project dirs
  -- * telescope
  --   * find files
  --   * live grep
  -- * grep workflow (:grep and gw)
  -- * toggleterm
  -- * (optional) better dir view, closer to defx

  distant.setup({
    ["*"] = {
      mode = "ssh",
      file = {
        mappings = {
          ["-"] = actions.up,
        },
      },
      dir = {
        mappings = {
          ["<Return>"] = actions.edit,
          ["-"] = actions.up,
          ["d"] = actions.mkdir,
          ["%"] = actions.newfile,
          ["r"] = actions.rename,
          ["D"] = actions.remove,
        },
      },
    },
  })
end)
