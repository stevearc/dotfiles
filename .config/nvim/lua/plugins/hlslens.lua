return {
  "kevinhwang91/nvim-hlslens",
  opts = {
    calm_down = true,
    nearest_only = true,
  },
  keys = {
    { "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], mode = "n" },
    { "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], mode = "n" },

    -- Fix * and # behavior to respect smartcase
    {
      "*",
      [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]],
      mode = "n",
    },
    {
      "#",
      [[:let @/='\v<'.expand('<cword>').'>'<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]],
      mode = "n",
    },
    {
      "g*",
      [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=1<CR>:lua require('hlslens').start()<CR>nzv]],
      mode = "n",
    },
    {
      "g#",
      [[:let @/='\v'.expand('<cword>')<CR>:let v:searchforward=0<CR>:lua require('hlslens').start()<CR>nzv]],
      mode = "n",
    },
  },
}
