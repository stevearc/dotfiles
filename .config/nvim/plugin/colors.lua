vim.opt.background = "dark"

local priority = {
  { mod = "nightfox", name = "duskfox" },
  {
    mod = "tokyonight",
  },
}

local colorschemes = {
  nightfox = function(nightfox)
    nightfox.setup({
      groups = {
        all = {
          -- Make and/or/not stand out more
          ["@keyword.operator"] = { link = "@keyword" },
        },
      },
    })
  end,
  tokyonight = function(tokyonight)
    tokyonight.setup({
      style = "night",
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        floats = "normal",
      },
      sidebars = vim.list_extend({ "qf", "help", "terminal" }, vim.g.sidebar_filetypes),
      on_highlights = function(highlights)
        for _, defn in pairs(highlights) do
          if defn.undercurl then
            defn.undercurl = false
            defn.underline = true
          end
        end
        highlights.AerialLineNC = { link = "LspReferenceText" }
        highlights.OverseerOutput = { link = "NormalSB" }
      end,
    })
  end,
}

local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
if is_tty then
  vim.opt.termguicolors = false
  vim.cmd("colorscheme darkblue")
else
  vim.opt.termguicolors = true

  local chosen
  for _, config in ipairs(priority) do
    local ok, mod = pcall(require, config.mod)
    if ok then
      colorschemes[config.mod](mod)
      if not chosen then
        chosen = config.name or config.mod
      end
    end
  end
  if chosen then
    vim.cmd(string.format("colorscheme %s", chosen))
  end

  safe_require("colorizer").setup()
end
