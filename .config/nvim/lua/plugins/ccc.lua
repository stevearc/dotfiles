local ccc_filetypes =
  { "html", "css", "sass", "less", "javascript", "typescript", "javascriptreact", "typescriptreact" }
return {
  "uga-rosa/ccc.nvim",
  cmd = { "CccPick" },
  config = function()
    local ccc = require("ccc")
    ccc.setup({
      inputs = {
        ccc.input.hsl,
        ccc.input.rgb,
      },
      highlighter = {
        auto_enable = true,
        filetypes = ccc_filetypes,
      },
      recognize = {
        input = true,
        output = true,
      },
      mappings = {
        ["?"] = function()
          print("i - Toggle input mode")
          print("o - Toggle output mode")
          print("a - Toggle alpha slider")
          print("g - Toggle palette")
          print("w - Go to next color in palette")
          print("b - Go to prev color in palette")
          print("l/d/, - Increase slider")
          print("h/s/m - Decrease slider")
          print("1-9 - Set slider value")
        end,
      },
    })
  end,
}
