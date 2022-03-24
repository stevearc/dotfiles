safe_require("lspconfig", function(lspconfig)
  -- vim.lsp.set_log_level("debug")

  vim.diagnostic.config({
    float = {
      source = "always",
    },
    virtual_text = {
      severity = { min = vim.diagnostic.severity.W },
      source = "if_many",
    },
    severity_sort = true,
  })

  if vim.g.nerd_font then
    vim.cmd([[
      sign define DiagnosticSignError text=   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=• numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=• numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
  else
    vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=. numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=. numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
  end

  -- Make all the "jump" commands call zv after execution
  local jump_callbacks = {
    "textDocument/declaration",
    "textDocument/definition",
    "textDocument/typeDefinition",
    "textDocument/implementation",
  }
  for _, cb in pairs(jump_callbacks) do
    local orig_callback = vim.lsp.handlers[cb]
    local new_callback = function(...)
      orig_callback(...)
      vim.cmd("normal! zv")
    end
    vim.lsp.handlers[cb] = new_callback
  end

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  local ft_config = {
    vim = {
      help = false,
    },
    lua = {
      help = false,
    },
    cs = {
      code_action = false, -- TODO: this borks the omnisharp server
    },
  }
  local diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, context, config)
    local client = vim.lsp.get_client_by_id(context.client_id)
    if client.config.diagnostics ~= false then
      diagnostics_handler(err, result, context, config)
    end
  end

  vim.lsp.handlers["window/showMessage"] = function(_err, result, context, _config)
    local client_id = context.client_id
    local message_type = result.type
    local message = result.message
    local client = vim.lsp.get_client_by_id(client_id)
    local client_name = client and client.name or string.format("id=%d", client_id)
    if not client then
      vim.notify("LSP[" .. client_name .. "] client has shut down after sending the message", vim.log.levels.ERROR)
    end
    if message_type == vim.lsp.protocol.MessageType.Error then
      vim.notify("LSP[" .. client_name .. "] " .. message, vim.log.levels.ERROR)
    else
      local message_type_name = vim.lsp.protocol.MessageType[message_type]
      local map = {
        Error = vim.log.levels.ERROR,
        Warning = vim.log.levels.WARN,
        Info = vim.log.levels.INFO,
        Log = vim.log.levels.DEBUG,
      }
      vim.notify(string.format("LSP[%s] %s\n", client_name, message), map[message_type_name])
    end
    return result
  end

  function stevearc.on_update_diagnostics(bufnr)
    local config = require("qf_helper.config")
    local util = require("qf_helper.util")
    if bufnr ~= vim.api.nvim_get_current_buf() or util.get_win_type() ~= "" then
      return
    end
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(winid) == bufnr then
        vim.diagnostic.setloclist({
          open = false,
          winnr = winid,
          severity = {
            min = vim.diagnostic.severity.W,
          },
        })
      end
    end
    if bufnr == vim.api.nvim_get_current_buf() then
      local total = vim.tbl_count(vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.W } }))
      if total == 0 then
        if vim.fn.win_gettype() == "" then
          vim.cmd("silent! lclose")
        end
        -- Resize the loclist
      elseif util.is_open("l") then
        local winid = vim.api.nvim_get_current_win()
        local height = math.max(config.l.min_height, math.min(config.l.max_height, total))
        vim.cmd("lopen " .. height)
        vim.api.nvim_set_current_win(winid)
      end
    end
  end
  function stevearc.diagnostics_enter_buffer()
    local util = require("qf_helper.util")
    if vim.bo.buftype ~= "" or not util.is_open("l") then
      return
    end
    local diagnostics = vim.diagnostic.get(0, {
      severity = {
        min = vim.diagnostic.severity.W,
      },
    })
    local items = vim.fn.getloclist(0)
    -- Only update the loclist if they're not already showing for our buffer
    if #diagnostics == #items and #items > 0 then
      local diag = diagnostics[1]
      local item = items[1]
      if diag.bufnr == item.bufnr and diag.lnum + 1 == item.lnum and diag.col + 1 == item.col then
        return
      end
    end
    stevearc.on_update_diagnostics(vim.api.nvim_get_current_buf())
  end

  local function adjust_formatting_capabilities(client, bufnr)
    if not pcall(require, "null-ls") then
      return
    end
    local sources = require("null-ls.sources")
    local methods = require("null-ls.methods")
    local null_ls_client = require("null-ls.client").get_client()
    if not null_ls_client or not vim.lsp.buf_is_attached(bufnr, null_ls_client.id) then
      return
    end
    local formatters = sources.get_available(vim.api.nvim_buf_get_option(bufnr, "filetype"), methods.FORMATTING)
    if vim.tbl_isempty(formatters) then
      return
    end
    if client.id == null_ls_client.id then
      -- We're attaching a null-ls client. If it has a formatter, disable
      -- formatting on all prior clients
      local clients = vim.lsp.buf_get_clients(bufnr)
      for _, other_client in ipairs(clients) do
        if other_client.id ~= client.id then
          other_client.resolved_capabilities.document_formatting = false
          other_client.resolved_capabilities.document_range_formatting = false
        end
      end
    else
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false
    end
  end

  vim.cmd([[augroup LSPDiagnostics
  au!
  autocmd DiagnosticChanged * call luaeval("stevearc.on_update_diagnostics(tonumber(_A))", expand("<abuf>"))
  autocmd BufEnter * lua stevearc.diagnostics_enter_buffer()
  augroup END]])

  local on_attach = function(client, bufnr)
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local config = ft_config[ft] or {}

    adjust_formatting_capabilities(client, bufnr)

    local function mapper(mode, key, result)
      vim.api.nvim_buf_set_keymap(bufnr, mode, key, result, { noremap = true, silent = true })
    end

    local function safemap(method, mode, key, result)
      if client.resolved_capabilities[method] then
        mapper(mode, key, result)
      end
    end

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(winid) == bufnr then
        vim.api.nvim_win_set_option(winid, "signcolumn", "yes")
      end
    end

    -- Standard LSP
    safemap("goto_definition", "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
    safemap("declaration", "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
    safemap("type_definition", "n", "gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
    safemap("implementation", "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
    safemap("find_references", "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
    if config.help ~= false then
      safemap("hover", "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
    end
    if client.resolved_capabilities.signature_help then
      mapper("i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
    end
    if config.code_action ~= false then
      mapper("n", "<leader>fa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
      mapper("v", "<leader>fa", ":<C-U>lua vim.lsp.buf.range_code_action()<CR>")
    end
    if client.resolved_capabilities.document_formatting then
      vim.cmd([[aug LspAutoformat
        au! * <buffer>
        autocmd BufWritePre <buffer> lua stevearc.autoformat()
        aug END
      ]])
      mapper("n", "=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
    end
    safemap("document_range_formatting", "v", "=", "<cmd>lua vim.lsp.buf.range_formatting()<CR>")
    safemap("rename", "n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")

    mapper("n", "<CR>", "<cmd>lua vim.diagnostic.open_float(0, {scope='line', border='rounded'})<CR>")

    if client.resolved_capabilities.document_highlight then
      vim.cmd([[aug LspShowReferences
        au! * <buffer>
        autocmd CursorHold,CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved,WinLeave <buffer> lua vim.lsp.buf.clear_references()
        aug END
      ]])
    end

    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    safe_require("aerial").on_attach(client, bufnr)
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  safe_require("cmp_nvim_lsp", function(cmp_nvim_lsp)
    capabilities = cmp_nvim_lsp.update_capabilities(capabilities)
  end)

  -- Configure the LSP servers
  local lspservers = {
    "bashls",
    "clangd",
    "cssls",
    "gdscript",
    "gopls",
    "html",
    "omnisharp",
    "rust_analyzer",
    "vimls",
  }
  for _, server in ipairs(lspservers) do
    lspconfig[server].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
  lspconfig.yamlls.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      yaml = {
        schemas = safe_require("schemastore").json.schemas(),
      },
    },
  })
  local function is_using_sqlalchemy()
    local util = lspconfig.util
    local path = util.path
    local setup = util.root_pattern("setup.cfg")(vim.loop.cwd())
    if not setup then
      return false
    end
    for line in io.lines(path.join(setup, "setup.cfg")) do
      if string.find(line, "sqlalchemy.ext.mypy.plugin") or string.find(line, "sqlmypy") then
        return true
      end
    end
    return false
  end
  lspconfig.pyright.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    -- pyright is real noisy when we're using sqlalchemy
    diagnostics = not is_using_sqlalchemy(),
  })
  lspconfig.jsonls.setup({
    filetypes = { "json", "jsonc", "json5" },
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      json = {
        schemas = safe_require("schemastore").json.schemas(),
      },
    },
  })

  lspconfig.tsserver.setup({
    capabilities = capabilities,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Disable tsserver when a flow project is detected
      if util.root_pattern(".flowconfig")(fname) then
        return nil
      end
      local ts_root = util.root_pattern("tsconfig.json")(fname)
        or util.root_pattern("package.json", "jsconfig.json", ".git")(fname)
      if ts_root then
        return ts_root
      end
      if vim.g.started_by_firenvim then
        return util.path.dirname(fname)
      end
      return nil
    end,
    on_attach = on_attach,
  })
  lspconfig.flow.setup({
    capabilities = capabilities,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Disable flow when a typescript project is detected
      if util.root_pattern("tsconfig.json")(fname) then
        return nil
      end
      return util.root_pattern(".flowconfig")(fname)
    end,
    on_attach = function(client, bufnr)
      require("flow").on_attach(client, bufnr)
      on_attach(client, bufnr)
    end,
    cmd = { "flow", "lsp", "--lazy" },
    settings = {
      flow = {
        coverageSeverity = "warn",
        showUncovered = true,
        stopFlowOnExit = false,
        useBundledFlow = false,
      },
    },
  })
  local sumneko_root_path = os.getenv("HOME") .. "/.local/share/nvim/language-servers/lua-language-server"
  local sumneko_binary = sumneko_root_path .. "/bin/Linux/lua-language-server"
  lspconfig.sumneko_lua.setup({
    capabilities = capabilities,
    cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";"),
        },
        diagnostics = {
          globals = { "vim", "stevearc", "safe_require" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = {
            [os.getenv("VIMRUNTIME") .. "/lua"] = true,
            [os.getenv("VIMRUNTIME") .. "/lua/vim/lsp"] = true,
          },
        },
        telemetry = {
          enable = false,
        },
      },
    },

    on_attach = on_attach,
  })

  lspconfig.sorbet.setup({
    capabilities = capabilities,
    cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
    on_attach = on_attach,
  })

  safe_require("null-ls", function(null_ls)
    null_ls.setup(vim.tbl_extend("keep", {
      capabilities = capabilities,
      root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern(".git", "Makefile", "setup.py", "setup.cfg", "pyproject.toml", "package.json")(fname)
          or util.path.dirname(fname)
      end,
      on_attach = on_attach,
    }, require("nullconfig")))
  end)
end)
