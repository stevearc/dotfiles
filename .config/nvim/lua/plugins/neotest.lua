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
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neotest/neotest-go",
    "nvim-neotest/neotest-jest",
    "nvim-neotest/neotest-plenary",
    "nvim-neotest/neotest-python",
    "nvim-neotest/nvim-nio",
    "stevearc/overseer.nvim",
  },
  keys = {
    {
      "<leader>tn",
      function() require("neotest").run.run({}) end,
      mode = "n",
      desc = "[T]est [N]earest",
    },
    {
      "<leader>tf",
      function() require("neotest").run.run({ vim.api.nvim_buf_get_name(0) }) end,
      mode = "n",
      desc = "[T]est [F]ile",
    },
    {
      "<leader>ta",
      function()
        for _, adapter_id in ipairs(require("neotest").run.adapters()) do
          require("neotest").run.run({ suite = true, adapter = adapter_id })
        end
      end,
      mode = "n",
      desc = "[T]est [A]ll",
    },
    {
      "<leader>tl",
      function() require("neotest").run.run_last() end,
      mode = "n",
      desc = "[T]est [L]ast",
    },
    {
      "<leader>td",
      function() require("neotest").run.run({ strategy = "dap" }) end,
      mode = "n",
      desc = "[T]est [D]ebug",
    },
    {
      "<leader>tp",
      function() require("neotest").summary.toggle() end,
      mode = "n",
      desc = "[T]est [P]anel toggle",
    },
    {
      "<leader>to",
      function() require("neotest").output.open({ short = true }) end,
      mode = "n",
      desc = "[T]est [O]utput",
    },
  },
  opts = {
    -- log_level = vim.log.levels.INFO,
    adapters = {
      ["neotest-python"] = {
        dap = { justMyCode = false },
      },
      ["neotest-plenary"] = false,
      ["neotest-go"] = false,
      ["neotest-jest"] = function()
        return {
          cwd = require("neotest-jest").root,
        }
      end,
    },
    discovery = {
      enabled = false,
    },
    consumers = {
      overseer = function() return require("neotest.consumers.overseer") end,
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
      running_animated = vim.tbl_map(
        function(s) return s .. " " end,
        { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
      ),
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
      enabled = false,
    },
    watch = {
      enabled = false,
    },
  },
  config = function(_, opts)
    local neotest = require("neotest")
    opts = vim.deepcopy(opts)

    local adapters = {}
    for k, v in pairs(opts.adapters) do
      if type(v) == "function" then
        table.insert(adapters, require(k)(v()))
      elseif v then
        table.insert(adapters, require(k)(v))
      else
        table.insert(adapters, require(k))
      end
    end
    opts.adapters = adapters

    for k, v in pairs(opts.consumers) do
      if type(v) == "function" then
        opts.consumers[k] = v()
      end
    end

    neotest.setup(opts)
  end,
}
