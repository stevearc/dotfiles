---@return nil|string
local function get_git_root()
  local root = vim.fs.find(".git", { upward = true })[1]
  if not root then
    return nil
  end
  return vim.fs.dirname(root)
end

---@param cmd string[]
---@param callback fun(files: string[])
local function run_files_cmd(cmd, callback)
  local root = get_git_root()
  if not root then
    return callback({})
  end
  vim.system(
    cmd,
    {
      text = true,
    },
    vim.schedule_wrap(function(proc)
      if proc.code ~= 0 then
        return callback({})
      end
      local ret = {}
      for name in vim.gsplit(proc.stdout, "\n", { plain = true }) do
        local fullname = root .. "/" .. name
        if vim.fn.filereadable(fullname) == 1 then
          table.insert(ret, fullname)
        end
      end
      callback(ret)
    end)
  )
end

---@param ref1? string
---@param ref2? string
---@param callback fun(err?: string, ref?: string)
local function merge_base(ref1, ref2, callback)
  ref1 = ref1 or "origin/master"
  ref2 = ref2 or "HEAD"
  vim.system(
    { "git", "merge-base", ref1, ref2 },
    { text = true },
    vim.schedule_wrap(function(proc)
      if proc.code ~= 0 then
        return callback("Error")
      else
        callback(nil, vim.trim(proc.stdout))
      end
    end)
  )
end

---@param files string[]
local function open_files(files)
  vim.cmd.tabnew()
  local has_three, three = pcall(require, "three")
  for _, file in ipairs(files) do
    vim.cmd.edit({ args = { file } })
    if has_three then
      three.set_pinned(vim.api.nvim_get_current_buf(), true)
    end
  end
end

---@return boolean
local function is_git_dirty()
  local proc = vim.system({ "git", "status", "--porcelain" }):wait()
  return proc.code ~= 0 or vim.trim(proc.stdout) ~= ""
end

return {
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    cmd = { "GitHistory", "Git", "GBrowse", "Gwrite", "GitEditDiffMaster", "GitEditDiff", "GitEdit" },
    keys = {
      { "<leader>gh", "<cmd>GitHistory<CR>", desc = "[G]it [H]istory" },
      { "<leader>gb", "<cmd>Git blame<CR>", desc = "[G]it [B]lame" },
      { "<leader>gc", "<cmd>GBrowse!<CR>", desc = "[G]it [C]opy link" },
      { "<leader>gc", ":GBrowse!<CR>", mode = "v", desc = "[G]it [C]opy link" },
    },
    config = function()
      vim.cmd("command! GitHistory Git! log -- %")

      vim.api.nvim_create_user_command("GitEditDiff", function()
        run_files_cmd({ "git", "diff", "--name-only" }, function(files)
          if vim.tbl_isempty(files) then
            vim.notify("No uncommitted changes", vim.log.levels.INFO)
            return
          end
          open_files(files)
        end)
      end, {
        desc = "Edit files with uncommitted changes",
      })

      vim.api.nvim_create_user_command("GitEditDiffMaster", function()
        merge_base(nil, nil, function(err, ref)
          if err or not ref then
            vim.notify("Error calculating merge base", vim.log.levels.ERROR)
            return
          end
          run_files_cmd({ "git", "diff", "--name-only", ref }, function(files)
            if vim.tbl_isempty(files) then
              vim.notify("No diff from master", vim.log.levels.INFO)
              return
            end
            open_files(files)
          end)
        end)
      end, {
        desc = "Edit files that differ from master",
      })

      vim.api.nvim_create_user_command("GitEdit", function(params)
        local git_dir = vim.fs.find(".git", { upward = true, path = vim.api.nvim_buf_get_name(0) })[1]
        if not git_dir then
          vim.notify("Not in a git repository", vim.log.levels.ERROR)
          return
        end
        local root = vim.fs.dirname(git_dir)
        local relpath = string.sub(vim.api.nvim_buf_get_name(0), root:len() + 2)
        local proc = vim
          .system({ "git", "rev-parse", "--verify", params.args }, {
            cwd = root,
          })
          :wait()
        if proc.code ~= 0 then
          vim.notify("Invalid commit hash: " .. params.args, vim.log.levels.ERROR)
          return
        end
        local rev = vim.trim(proc.stdout)
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        vim.cmd.edit({
          args = {
            "fugitive://" .. git_dir .. "//" .. rev .. "/" .. relpath,
          },
        })
        pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
      end, {
        desc = "Edit current file at a specific commit",
        nargs = 1,
      })
    end,
  },
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = { "CodeDiff", "GitReview" },
    opts = {
      keymaps = {
        view = {
          quit = "gq",
          next_hunk = "]h",
          prev_hunk = "[h",
          next_file = "]g",
          prev_file = "[g",
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)

      vim.api.nvim_create_user_command("GitReview", function(params)
        local base = params.fargs[1]
        if not base then
          if is_git_dirty() then
            base = "@"
          else
            local proc = vim.system({ "git", "stack", "show-base" }, { text = true }):wait()
            if proc.code ~= 0 then
              proc = vim.system({ "git", "merge-base", "master" }, { text = true }):wait()
              if proc.code ~= 0 then
                vim.notify(string.format("Error finding merge base: %s", proc.stdout), vim.log.levels.ERROR)
                return
              end
            end
            base = vim.trim(proc.stdout)
          end
        end

        vim.cmd.CodeDiff(base)
      end, {
        desc = "Review a git diff in vim",
        nargs = "?",
      })
    end,
  },
}
