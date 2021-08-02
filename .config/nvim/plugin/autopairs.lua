local npairs = require("nvim-autopairs")
npairs.setup()
require("nvim-autopairs.completion.compe").setup({
  map_cr = true,
  map_complete = true,
})
