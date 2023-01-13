return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "b0o/SchemaStore.nvim",
      {
        "j-hui/fidget.nvim",
        opts = {
          text = {
            spinner = "dots",
          },
          window = {
            relative = "editor",
          },
        },
      },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local lsp = require("lsp")
      local p = require("p")
      -- vim.lsp.set_log_level("debug")

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
            pickers
              .new(opts, {
                prompt_title = "LSP Locations",
                finder = finders.new_table({
                  results = items,
                  entry_maker = make_entry.gen_from_quickfix(opts),
                }),
                previewer = conf.qflist_previewer(opts),
                sorter = conf.generic_sorter(opts),
              })
              :find()
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
      vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

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

      -- Configure the LSP servers
      local lspservers = {
        "bashls",
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
        lsp.safe_setup(server)
      end
      lsp.safe_setup("yamlls", {
        settings = {
          yaml = {
            schemas = p.require("schemastore").json.schemas(),
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
      lsp.safe_setup("pyright", {
        -- pyright is real noisy when we're using sqlalchemy
        diagnostics = not is_using_sqlalchemy(),
      })
      lsp.safe_setup("clangd", {
        filetypes = { "c", "cpp", "objc", "objcpp" },
      })
      lsp.safe_setup("jsonls", {
        filetypes = { "json", "jsonc", "json5" },
        settings = {
          json = {
            schemas = p.require("schemastore").json.schemas(),
          },
        },
      })

      lsp.safe_setup("tsserver", {
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
      })
      lsp.safe_setup("flow", {
        root_dir = function(fname)
          local util = require("lspconfig.util")
          -- Disable flow when a typescript project is detected
          if util.root_pattern("tsconfig.json")(fname) then
            return nil
          end
          return util.root_pattern(".flowconfig")(fname)
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

      -- conflicts with work
      -- lspconfig.sorbet.setup({
      --   capabilities = lsp.capabilities,
      --   cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
      -- })

      local group = vim.api.nvim_create_augroup("LspSetup", {})
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "My custom attach behavior",
        pattern = "*",
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          lsp.on_attach(client, args.buf)
        end,
      })
      -- vim.cmd("silent! LspStart")
    end,
  },

  {
    "stevearc/flow-coverage.nvim",
    ft = { "javascript", "javascript.jsx", "javascriptreact" },
  },

  {
    "folke/neodev.nvim",
    opts = { experimental = { pathStrict = true } },
    ft = "lua",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function(_, opts)
      require("neodev").setup(opts)
      local lsp = require("lsp")
      local sumneko_root_path = os.getenv("HOME") .. "/.local/share/nvim/language-servers/lua-language-server"
      local sumneko_binary = sumneko_root_path .. "/bin/lua-language-server"
      lsp.safe_setup("sumneko_lua", {
        cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
        settings = {
          Lua = {
            IntelliSense = {
              traceLocalSet = true,
            },
            diagnostics = {
              globals = { "vim", "it", "describe", "before_each", "after_each", "a" },
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
    end,
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    event = "VeryLazy",
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup(vim.tbl_extend("keep", {
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern(".git", "Makefile", "setup.py", "setup.cfg", "pyproject.toml", "package.json")(fname)
            or util.path.dirname(fname)
        end,
      }, require("nullconfig")))
    end,
  },
}
