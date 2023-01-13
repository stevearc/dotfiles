return {
  "kevinhwang91/nvim-hlslens",
  opts = {
    calm_down = true,
    nearest_only = true,
  },
  event = "VeryLazy",
  config = function(_, opts)
    require("hlslens").setup(opts)

    vim.keymap.set("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]])
    vim.keymap.set("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]])

    -- Fix * and # behavior to respect smartcase
    vim.keymap.set(
      "n",
      "*",
      [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]]
    )
    vim.keymap.set(
      "n",
      "#",
      [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]]
    )
    vim.keymap.set(
      "n",
      "g*",
      [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]]
    )
    vim.keymap.set(
      "n",
      "g#",
      [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]]
    )
  end,
}
