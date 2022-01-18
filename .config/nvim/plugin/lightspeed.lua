safe_require("lightspeed", function(lightspeed)
  lightspeed.setup({
    jump_to_unique_chars = false,
    safe_labels = nil,
  })

  -- Disable all of lightspeed's default keymaps
  for _, key in ipairs({ "s", "S", "f", "F", "t", "T", ";", "," }) do
    vim.api.nvim_del_keymap("", key)
  end
  vim.api.nvim_set_keymap("", "<leader>j", "<Plug>Lightspeed_s", {})
  vim.api.nvim_set_keymap("", "<leader>k", "<Plug>Lightspeed_S", {})
end)
