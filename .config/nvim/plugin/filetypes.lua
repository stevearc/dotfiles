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
    keys = {
      { "<leader>ac", ":wa<CR>:ArduinoVerify<CR>" },
      { "<leader>au", ":wa<CR>:ArduinoUpload<CR>" },
      { "<leader>ad", ":wa<CR>:ArduinoUploadAndSerial<CR>" },
      { "<leader>ab", "<CMD>ArduinoChooseBoard<CR>" },
      { "<leader>ap", "<CMD>ArduinoChooseProgrammer<CR>" },
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
  DressingInput = {
    keys = {
      { "<C-k>", '<CMD>lua require("dressing.input").history_prev()<CR>', mode = "i" },
      { "<C-j>", '<CMD>lua require("dressing.input").history_next()<CR>', mode = "i" },
    },
  },
  fugitiveblame = {
    keys = {
      { "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  go = {
    compiler = "go",
    opt = {
      list = false,
      listchars = "nbsp:⦸,extends:»,precedes:«,tab:  ",
    },
  },
  help = {
    keys = {
      { "gd", "<C-]>" },
    },
    opt = {
      list = false,
      textwidth = 80,
    },
    callback = function(bufnr)
      vim.api.nvim_create_user_command("Browse", function()
        local filename = vim.fn.expand("%:t:r")
        local url = "https://neovim.io/doc/user/" .. filename .. ".html"
        vim.ui.open(url)
      end, {})
    end,
  },
  lua = {
    abbr = {
      ["!="] = "~=",
      locla = "local",
      vll = "vim.log.levels",
    },
    keys = {
      { "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
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
      breakindentopt = "list:-1",
      comments = "sb:- [x],mb:- [ ],b:-,b:*,b:>",
      conceallevel = 2,
      formatlistpat = "\\C^\\s*[\\[({]\\?\\([0-9]\\+\\|[iIvVxXlLcCdDmM]\\+\\|[a-zA-Z]\\)[\\]:.)}]\\s\\+\\|^\\s*[-+o*>]\\s\\+",
      formatoptions = "jqlnr",
      linebreak = true,
      shiftwidth = 2,
      softtabstop = 2,
      suffixesadd = ".md",
      tabstop = 2,
      undofile = true,
      wrap = true,
    },
    keys = {
      { "<leader>td", require("markdown").task_mark_done },
      { "<leader>tu", require("markdown").task_mark_undone },
    },
    callback = function(bufnr)
      require("markdown").update_code_highlights(bufnr)
      local aug = vim.api.nvim_create_augroup("MarkdownStyling", {})
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = aug })
      vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
        buffer = bufnr,
        callback = vim.schedule_wrap(function(args) require("markdown").update_code_highlights(bufnr) end),
      })
      vim.keymap.set("i", "<Tab>", function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        line = line:sub(1, col)
        local is_list = line:match("^%s*[%-%*]%s*")
        if col == #line and is_list then
          return "<Left><C-o>>><C-o><Right>" .. string.rep("<Right>", vim.bo.tabstop)
        end
        return "<Tab>"
      end, { expr = true, buffer = bufnr })
      vim.keymap.set("i", "<BS>", function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local max_left = #line - col
        line = line:sub(1, col)
        local is_list = line:match("^%s+[%-%*]%s+$") or line:match("^%s+[%-%*]%s*%[.%]%s+$")
        if col == #line and is_list then
          return "<C-o><<<C-o>" .. string.rep("<Left>", math.min(max_left, vim.bo.tabstop))
        end
        return "<BS>"
      end, { expr = true, buffer = bufnr })
    end,
  },
  ["neotest-summary"] = {
    opt = {
      wrap = false,
    },
  },
  norg = {
    opt = {
      comments = "n:-,n:( )",
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
      linebreak = true,
      wrap = true,
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
          vim.cmd.write()
          vim.cmd("silent !autoimport " .. vim.api.nvim_buf_get_name(0))
          vim.cmd.edit()
          vim.lsp.buf.formatting({})
        end, { buffer = bufnr })
      end
      vim.keymap.set(
        "n",
        "<leader>e",
        function() run_file({ "python", vim.api.nvim_buf_get_name(0) }) end,
        { buffer = bufnr }
      )
    end,
  },
  rust = {
    compiler = "cargo",
    callback = function(bufnr)
      vim.keymap.set("n", "<leader>e", function() run_file({ "cargo", "run" }) end, { buffer = bufnr })
    end,
  },
  sh = {
    callback = function(bufnr)
      vim.keymap.set(
        "n",
        "<leader>e",
        function() run_file({ "bash", vim.api.nvim_buf_get_name(0) }) end,
        { buffer = bufnr }
      )
    end,
  },
  supercollider = {
    keys = {
      { "<CR>", "<Plug>(scnvim-send-block)" },
      { "<c-CR>", "<Plug>(scnvim-send-block)", mode = "i" },
      { "<CR>", "<Plug>(scnvim-send-selection)", mode = "x" },
      { "<F1>", "<cmd>call scnvim#install()<CR><cmd>SCNvimStart<CR><cmd>SCNvimStatusLine<CR>" },
      { "<F2>", "<cmd>SCNvimStop<CR>" },
      { "<F12>", "<Plug>(scnvim-hard-stop)" },
      { "<leader><space>", "<Plug>(scnvim-postwindow-toggle)" },
      { "<leader>g", "<cmd>call scnvim#sclang#send('s.plotTree;')<CR>" },
      { "<leader>s", "<cmd>call scnvim#sclang#send('s.scope;')<CR>" },
      { "<leader>f", "<cmd>call scnvim#sclang#send('FreqScope.new;')<CR>" },
      { "<leader>r", "<cmd>SCNvimRecompile<CR>" },
      { "<leader>m", "<cmd>call scnvim#sclang#send('Master.gui;')<CR>" },
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
  typescript = {
    compiler = "tsc",
  },
  vim = {
    opt = {
      foldmethod = "marker",
      keywordprg = ":help",
    },
  },
  zig = {
    compiler = "zig_test",
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
    },
  },
})

ftplugin.setup()
