local uv = vim.uv or vim.loop
local is_mac = uv.os_uname().sysname == "Darwin"

return {
  "3rd/image.nvim",
  ft = { "markdown", "norg", "oil" },
  build = function()
    local has_magick = pcall(require, "magick")
    if not has_magick and vim.fn.executable("luarocks") == 1 then
      if is_mac then
        vim.fn.system("luarocks --lua-dir=$(brew --prefix)/opt/lua@5.1 --lua-version=5.1 install magick")
      else
        vim.fn.system("luarocks --local --lua-version=5.1 install magick")
      end
      if vim.v.shell_error ~= 0 then
        vim.notify("Error installing magick with luarocks", vim.log.levels.WARN)
      end
    end
  end,
  opts = {
    editor_only_render_when_focused = true,
    tmux_show_only_in_active_window = true,
  },
  config = function(_, opts)
    local has_magick = pcall(require, "magick")
    if has_magick then
      require("image").setup(opts)
    end
  end,
}
