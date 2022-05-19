local lsp = require("lsp")
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

  local function location_handler(_, result, ctx, _)
    if result == nil or vim.tbl_isempty(result) then
      return nil
    end
    local client = vim.lsp.get_client_by_id(ctx.client_id)

    -- textDocument/definition can return Location or Location[]
    -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition

    local has_telescope = pcall(require, "telescope")
    if vim.tbl_islist(result) then
      if #result == 1 then
        vim.lsp.util.jump_to_location(result[1], client.offset_encoding)
      elseif has_telescope then
        local opts = {}
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local make_entry = require("telescope.make_entry")
        local conf = require("telescope.config").values
        local items = vim.lsp.util.locations_to_items(result, client.offset_encoding)
        pickers.new(opts, {
          prompt_title = "LSP Locations",
          finder = finders.new_table({
            results = items,
            entry_maker = make_entry.gen_from_quickfix(opts),
          }),
          previewer = conf.qflist_previewer(opts),
          sorter = conf.generic_sorter(opts),
        }):find()
      else
        vim.fn.setqflist({}, " ", {
          title = "LSP locations",
          items = vim.lsp.util.locations_to_items(result, client.offset_encoding),
        })
        vim.cmd([[botright copen]])
      end
    else
      vim.lsp.util.jump_to_location(result, client.offset_encoding)
    end
  end

  vim.lsp.handlers["textDocument/declaration"] = location_handler
  vim.lsp.handlers["textDocument/definition"] = location_handler
  vim.lsp.handlers["textDocument/typeDefinition"] = location_handler
  vim.lsp.handlers["textDocument/implementation"] = location_handler

  vim.lsp.handlers["textDocument/formatting"] = function(_, result, ctx, _)
    if not result then
      return
    end
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local restore = lsp.save_win_positions(ctx.bufnr)
    vim.lsp.util.apply_text_edits(result, ctx.bufnr, client.offset_encoding)
    restore()
  end

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

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

  vim.cmd([[augroup LSPDiagnostics
  au!
  autocmd DiagnosticChanged * call luaeval("stevearc.on_update_diagnostics(tonumber(_A))", expand("<abuf>"))
  autocmd BufEnter * lua stevearc.diagnostics_enter_buffer()
  augroup END]])

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
    "zls",
  }
  for _, server in ipairs(lspservers) do
    lspconfig[server].setup({
      capabilities = lsp.capabilities,
      on_attach = lsp.on_attach,
    })
  end
  lspconfig.yamlls.setup({
    capabilities = lsp.capabilities,
    on_attach = lsp.on_attach,
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
    capabilities = lsp.capabilities,
    on_attach = lsp.on_attach,
    -- pyright is real noisy when we're using sqlalchemy
    diagnostics = not is_using_sqlalchemy(),
  })
  lspconfig.jsonls.setup({
    filetypes = { "json", "jsonc", "json5" },
    capabilities = lsp.capabilities,
    on_attach = lsp.on_attach,
    settings = {
      json = {
        schemas = safe_require("schemastore").json.schemas(),
      },
    },
  })

  lspconfig.tsserver.setup({
    capabilities = lsp.capabilities,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Disable tsserver on js files when a flow project is detected
      if not string.match(fname, ".tsx?$") and util.root_pattern(".flowconfig")(fname) then
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
    on_attach = lsp.on_attach,
  })
  lspconfig.flow.setup({
    capabilities = lsp.capabilities,
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Disable flow when a typescript project is detected
      if util.root_pattern("tsconfig.json")(fname) then
        return nil
      end
      return util.root_pattern(".flowconfig")(fname)
    end,
    on_attach = function(client, bufnr)
      safe_require("flow").on_attach(client, bufnr)
      lsp.on_attach(client, bufnr)
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
    capabilities = lsp.capabilities,
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

    on_attach = lsp.on_attach,
  })

  lspconfig.sorbet.setup({
    capabilities = lsp.capabilities,
    cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
    on_attach = lsp.on_attach,
  })

  safe_require("null-ls", function(null_ls)
    null_ls.setup(vim.tbl_extend("keep", {
      capabilities = lsp.capabilities,
      root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern(".git", "Makefile", "setup.py", "setup.cfg", "pyproject.toml", "package.json")(fname)
          or util.path.dirname(fname)
      end,
      on_attach = lsp.on_attach,
    }, require("nullconfig")))
  end)
end)
