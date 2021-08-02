require("tabout").setup({
  tabkey = "",
  backwards_tabkey = "<S-Tab>",
  act_as_tab = true,
  act_as_shift_tab = true,
  enable_backwards = true,
  completion = false,
})

local function replace_keycodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.clevertab()
  if vim.fn["vsnip#available"](1) ~= 0 then
    return replace_keycodes("<Plug>(vsnip-expand-or-jump)")
  else
    return replace_keycodes("<Plug>(Tabout)")
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.clevertab()", { expr = true })
