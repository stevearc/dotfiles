local lsp = require("lsp")

local jdtls = os.getenv("HOME") .. "/.local/share/jdtls"
local configuration
if vim.loop.os_uname().version:match("Windows") then
  configuration = jdtls .. "/config_win"
elseif vim.loop.os_uname().sysname == "Darwin" then
  configuration = jdtls .. "/config_mac"
else
  configuration = jdtls .. "/config_linux"
end

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = os.getenv("HOME") .. "/.cache/nvim/jdtls/" .. project_name
local launcher = vim.fn.glob(jdtls .. "/plugins/org.eclipse.equinox.launcher_*")

local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xms1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    launcher,
    "-configuration",
    configuration,
    "-data",
    workspace_dir,
  },

  root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {},
  },

  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = {},
  },

  on_attach = lsp.on_attach,
}

if vim.fn.executable("java") == 1 and launcher ~= "" then
  safe_require("jdtls").start_or_attach(config)
end
