local p = require("p")

p.require("quick_action", function(quick_action) quick_action.set_keymap("n", "<CR>", "menu") end)
