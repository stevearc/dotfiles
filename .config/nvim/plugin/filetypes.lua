local p = require("p")
local ftplugin = p.require("ftplugin")

local function run_file(cmd)
  vim.cmd.update()
  local task = require("overseer").new_task({
    cmd = cmd,
    components = { "unique", "default" },
  })
  task:start()
  local bufnr = task:get_bufnr()
  if bufnr then
    vim.cmd.split()
    vim.api.nvim_win_set_buf(0, bufnr)
  end
end

ftplugin.extend_all({
  arduino = {
    bindings = {
      { "n", "<leader>ac", ":wa<CR>:ArduinoVerify<CR>" },
      { "n", "<leader>au", ":wa<CR>:ArduinoUpload<CR>" },
      { "n", "<leader>ad", ":wa<CR>:ArduinoUploadAndSerial<CR>" },
      { "n", "<leader>ab", "<CMD>ArduinoChooseBoard<CR>" },
      { "n", "<leader>ap", "<CMD>ArduinoChooseProgrammer<CR>" },
    },
  },
  cs = {
    opt = {
      foldlevel = 0,
      foldmethod = "syntax",
    },
    bufvar = {
      match_words = "\\s*#\\s*region.*$:\\s*#\\s*endregion",
      all_folded = 1,
    },
  },
  defx = {
    opt = {
      bufhidden = "wipe",
    },
  },
  DressingInput = {
    bindings = {
      { "i", "<C-k>", '<CMD>lua require("dressing.input").history_prev()<CR>' },
      { "i", "<C-j>", '<CMD>lua require("dressing.input").history_next()<CR>' },
    },
  },
  fugitiveblame = {
    bindings = {
      { "n", "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  go = {
    opt = {
      list = false,
      listchars = "nbsp:⦸,extends:»,precedes:«,tab:  ",
    },
  },
  help = {
    bindings = {
      { "n", "gd", "<C-]>" },
    },
    opt = {
      list = false,
      textwidth = 80,
    },
  },
  lua = {
    abbr = {
      ["!="] = "~=",
      locla = "local",
      vll = "vim.log.levels",
    },
    bindings = {
      { "n", "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
    },
    opt = {
      comments = ":---,:--",
    },
  },
  make = {
    opt = {
      expandtab = false,
    },
  },
  markdown = {
    opt = {
      conceallevel = 2,
      formatoptions = "jqln",
    },
  },
  ["neotest-summary"] = {
    opt = {
      wrap = false,
    },
  },
  norg = {
    opt = {
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
    },
  },
  python = {
    abbr = {
      inn = "is not None",
      ipmort = "import",
      improt = "import",
    },
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
      textwidth = 88,
    },
    callback = function(bufnr)
      if vim.fn.executable("autoimport") == 1 then
        vim.keymap.set("n", "<leader>o", function()
          vim.cmd("write")
          vim.cmd("silent !autoimport " .. vim.api.nvim_buf_get_name(0))
          vim.cmd("edit")
          vim.lsp.buf.formatting({})
        end, { buffer = bufnr })
      end
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "python", vim.api.nvim_buf_get_name(0) })
      end, { buffer = bufnr })
    end,
  },
  qf = {
    opt = {
      winfixheight = true,
      relativenumber = false,
      buflisted = false,
    },
  },
  rust = {
    opt = {
      makeprg = "cargo $*",
    },
    callback = function(bufnr)
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "cargo", "run" })
      end, { buffer = bufnr })
    end,
  },
  sh = {
    callback = function(bufnr)
      -- Highlight variables inside strings
      vim.cmd([[
        hi link TSConstant Identifier
        hi link TSVariable Identifier
      ]])
      vim.keymap.set("n", "<leader>e", function()
        run_file({ "bash", vim.api.nvim_buf_get_name(0) })
      end, { buffer = bufnr })
    end,
  },
  supercollider = {
    bindings = {
      { "n", "<CR>", "<Plug>(scnvim-send-block)", { remap = false } },
      { "i", "<c-CR>", "<Plug>(scnvim-send-block)", { remap = false } },
      { "x", "<CR>", "<Plug>(scnvim-send-selection)", { remap = false } },
      { "n", "<F1>", "<cmd>call scnvim#install()<CR><cmd>SCNvimStart<CR><cmd>SCNvimStatusLine<CR>" },
      { "n", "<F2>", "<cmd>SCNvimStop<CR>" },
      { "n", "<F12>", "<Plug>(scnvim-hard-stop)", { remap = false } },
      { "n", "<leader><space>", "<Plug>(scnvim-postwindow-toggle)", { remap = false } },
      { "n", "<leader>g", "<cmd>call scnvim#sclang#send('s.plotTree;')<CR>" },
      { "n", "<leader>s", "<cmd>call scnvim#sclang#send('s.scope;')<CR>" },
      { "n", "<leader>f", "<cmd>call scnvim#sclang#send('FreqScope.new;')<CR>" },
      { "n", "<leader>r", "<cmd>SCNvimRecompile<CR>" },
      { "n", "<leader>m", "<cmd>call scnvim#sclang#send('Master.gui;')<CR>" },
    },
    opt = {
      foldmethod = "marker",
      foldmarker = "{{{,}}}",
      statusline = "%f %h%w%m%r %{scnvim#statusline#server_status()} %= %(%l,%c%V %= %P%)",
    },
    callback = function(bufnr)
      vim.api.nvim_create_autocmd("WinEnter", {
        pattern = "*",
        command = "if winnr('$') == 1 && getbufvar(winbufnr(winnr()), '&filetype') == 'scnvim'|q|endif",
        group = "ClosePostWindowIfLast",
      })
    end,
  },
  vim = {
    opt = {
      foldmethod = "marker",
      keywordprg = ":help",
    },
  },
  zig = {
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
    },
  },
})

ftplugin.setup()
