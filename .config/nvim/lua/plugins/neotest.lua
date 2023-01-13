local lazy = require("lazy")
-- Todo:
-- * Bug: Running tests on directory doesn't work if directory not in tree (but tree has subdirectories)
-- * Bug: No output or debug info if test fails to run (e.g. try running tests in cpython)
-- * Bug: Sometimes issues with running python tests (dir position stuck in running state)
-- * Bug: Files shouldn't appear in summary if they contain no tests (e.g. python file named 'test_*.py')
-- * Bug: dir/file/namespace status should be set by children
-- * Bug: Run last test doesn't work with marked tests (if ran all marked last)
-- * Feat: If summary tree only has a single (file/dir) child, merge the display
-- * Feat: Different bindings for expand/collapse
-- * Feat: Can collapse tree on a child node
-- * Feat: Can't rerun failed tests
-- * Feat: Configure adapters & discovery on a per-directory basis
-- Investigate:
-- * Does neotest have ability to throttle groups of individual test runs?
-- * Tangential, but also check out https://github.com/andythigpen/nvim-coverage
lazy.require(
  "neotest",
  "neotest-python",
  "neotest-plenary",
  "neotest-jest",
  function(neotest, python_adapter, plenary_adapter, jest_adapter)
    -- require("neotest.logging"):set_level("trace")
    neotest.setup({
      adapters = {
        python_adapter({
          dap = { justMyCode = false },
        }),
        plenary_adapter,
        jest_adapter({
          cwd = jest_adapter.root,
        }),
      },
      discovery = {
        enabled = false,
      },
      consumers = {
        overseer = lazy.require("neotest.consumers.overseer"),
      },
      summary = {
        mappings = {
          attach = "a",
          expand = "l",
          expand_all = "L",
          jumpto = "gf",
          output = "o",
          run = "<C-r>",
          short = "p",
          stop = "u",
        },
      },
      icons = {
        passed = " ",
        running = " ",
        failed = " ",
        unknown = " ",
        running_animated = vim.tbl_map(function(s)
          return s .. " "
        end, { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }),
      },
      diagnostic = {
        enabled = true,
      },
      output = {
        enabled = true,
        open_on_run = false,
      },
      status = {
        enabled = true,
      },
      quickfix = {
        open = false,
      },
    })
    vim.keymap.set("n", "<leader>tn", function()
      neotest.run.run({})
    end)
    vim.keymap.set("n", "<leader>tt", function()
      neotest.run.run({ vim.api.nvim_buf_get_name(0) })
    end)
    vim.keymap.set("n", "<leader>ta", function()
      for _, adapter_id in ipairs(neotest.run.adapters()) do
        neotest.run.run({ suite = true, adapter = adapter_id })
      end
    end)
    vim.keymap.set("n", "<leader>tl", function()
      neotest.run.run_last()
    end)
    vim.keymap.set("n", "<leader>td", function()
      neotest.run.run({ strategy = "dap" })
    end)
    vim.keymap.set("n", "<leader>tp", function()
      neotest.summary.toggle()
    end)
    vim.keymap.set("n", "<leader>to", function()
      neotest.output.open({ short = true })
    end)
  end
)
