local p = require("p")

return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "b0o/SchemaStore.nvim",
    },
    opts = {
      servers = {
        bashls = {},
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp" },
        },
        cssls = {},
        eslint = {},
        flow = {
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
        },
        gdscript = {},
        gopls = {},
        html = {},
        jsonls = function()
          return {
            filetypes = { "json", "jsonc", "json5" },
            settings = {
              json = {
                schemas = p.require("schemastore").json.schemas(),
              },
            },
          }
        end,
        lua_ls = function()
          local sumneko_root_path = vim.uv.os_homedir() .. "/.local/share/nvim/language-servers/lua-language-server"
          local sumneko_binary = sumneko_root_path .. "/bin/lua-language-server"
          return {
            cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
            settings = {
              Lua = {
                hint = {
                  enable = true,
                },
                IntelliSense = {
                  traceLocalSet = true,
                },
                diagnostics = {
                  globals = { "assert", "it", "describe", "before_each", "after_each", "a" },
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          }
        end,
        omnisharp = {},
        pyright = {},
        ruff = {},
        rust_analyzer = {},
        sorbet = {
          cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
        },
        vimls = {},
        yamlls = function()
          return {
            settings = {
              yaml = {
                schemas = p.require("schemastore").json.schemas(),
              },
            },
          }
        end,
        zls = {},
      },
    },
    config = function(_, opts)
      -- vim.lsp.set_log_level("debug")

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
          -- The whole reason to override this handler is so that this uses vim.notify instead of
          -- vim.api.nvim_out_write
          vim.notify(string.format("LSP[%s] %s\n", client_name, message), map[message_type_name])
        end
        return result
      end

      -- Configure the LSP servers
      for k, v in pairs(opts.servers) do
        if v then
          if type(v) == "function" then
            v = v()
          end
          if not v then
            vim.lsp.enable(k, false)
          else
            if vim.tbl_isempty(v) then
              v = {}
            end
            if type(v) == "table" then
              vim.lsp.config(k, v)
            end
            vim.lsp.enable(k, true)
          end
        end
      end

      local group = vim.api.nvim_create_augroup("LspSetup", {})
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "My custom attach behavior",
        pattern = "*",
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          require("lsp_util").on_attach(client, args.buf)
        end,
      })
    end,
  },

  {
    "folke/lazydev.nvim",
    dependencies = {
      { "Bilal2453/luvit-meta" },
    },
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv", "vim%.loop" } },
      },
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
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
          return vim.fs.dirname(fname)
        end
        return nil
      end,
      settings = {
        separate_diagnostic_server = false,
        tsserver_max_memory = 8 * 1024,
      },
    },
  },

  -- {
  --   "mfussenegger/nvim-jdtls",
  --   ft = "java",
  --   dependencies = { "neovim/nvim-lspconfig" },
  --   config = function()
  --     local aug = vim.api.nvim_create_augroup("Jdtls", {})
  --     vim.api.nvim_create_autocmd("FileType", {
  --       desc = "Start JDTLS",
  --       pattern = "java",
  --       group = aug,
  --       callback = function(args)
  --         local local_share = uv.os_homedir() .. "/.local/share"
  --         local jdtls_root = local_share .. "/jdtls"
  --         local configuration
  --         if uv.os_uname().version:match("Windows") then
  --           configuration = jdtls_root .. "/config_win"
  --         elseif uv.os_uname().sysname == "Darwin" then
  --           configuration = jdtls_root .. "/config_mac"
  --         else
  --           configuration = jdtls_root .. "/config_linux"
  --         end
  --         if vim.fn.isdirectory(configuration) == 0 then
  --           return
  --         end
  --
  --         local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  --         local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name
  --         local launcher = vim.fn.glob(jdtls_root .. "/plugins/org.eclipse.equinox.launcher_*.jar")
  --         if launcher == "" then
  --           return
  --         end
  --
  --         -- Look for a local install of java
  --         local java_cmd = vim.fn.glob(local_share .. "/java/Home/bin/java")
  --         if java_cmd == "" then
  --           java_cmd = "java"
  --         end
  --         if vim.fn.executable(java_cmd) == 0 then
  --           return
  --         end
  --
  --         -- Possibly not supposed to include all of these jar files https://github.com/salesforce/bazel-vscode/blob/c7f5b7476a425b3f6481c9b23c1057d894c3ed33/package.json#L23
  --         local extension_dirs = { local_share .. "/bazel-eclipse/plugins/*.jar" }
  --         local bundles = {}
  --         for _, glob in ipairs(extension_dirs) do
  --           vim.list_extend(bundles, vim.split(vim.fn.glob(glob), "\n"))
  --         end
  --
  --         local config = {
  --           cmd = {
  --             java_cmd,
  --             "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  --             "-Dosgi.bundles.defaultStartLevel=4",
  --             "-Declipse.product=org.eclipse.jdt.ls.core.product",
  --             "-Dlog.protocol=true",
  --             "-Dlog.level=ALL",
  --             "-Xmx4G",
  --             "-Xms4G",
  --             "--add-modules=ALL-SYSTEM",
  --             "--add-opens",
  --             "java.base/java.util=ALL-UNNAMED",
  --             "--add-opens",
  --             "java.base/java.lang=ALL-UNNAMED",
  --             "-jar",
  --             launcher,
  --             "-configuration",
  --             configuration,
  --             "-data",
  --             workspace_dir,
  --           },
  --
  --           root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", ".bazelrc" }),
  --
  --           -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  --           -- for a list of options
  --           settings = require("projects")[args.buf].lsp_settings.jdtls or {},
  --
  --           init_options = {
  --             bundles = bundles,
  --           },
  --           capabilities = require("lsp").capabilities,
  --         }
  --
  --         vim.api.nvim_buf_call(args.buf, function()
  --           require("jdtls").start_or_attach(config)
  --         end)
  --       end,
  --     })
  --   end,
  -- },
}
