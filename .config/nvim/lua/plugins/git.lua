vim.keymap.set("n", "<leader>gt", function() require("gitterm").toggle() end, { desc = "[G]it [T]erminal interface" })

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
  local stdout = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _) vim.list_extend(stdout, data) end,
    on_exit = function(_, code)
      if code ~= 0 then
        return callback({})
      end
      local ret = {}
      for _, name in ipairs(stdout) do
        local fullname = root .. "/" .. name
        if vim.fn.filereadable(fullname) == 1 then
          table.insert(ret, fullname)
        end
      end
      callback(ret)
    end,
  })
end

---@param ref1? string
---@param ref2? string
---@param callback fun(err?: string, ref?: string)
local function merge_base(ref1, ref2, callback)
  ref1 = ref1 or "origin/master"
  ref2 = ref2 or "HEAD"
  local stdout = ""
  vim.fn.jobstart({ "git", "merge-base", ref1, ref2 }, {
    stdout_buffered = true,
    on_stdout = function(_, data, _) stdout = vim.trim(table.concat(data, "\n")) end,
    on_exit = function(_, code)
      if code ~= 0 then
        return callback("Error")
      else
        callback(nil, stdout)
      end
    end,
  })
end

---@param files string[]
local function open_files(files)
  vim.cmd.tabnew()
  for _, file in ipairs(files) do
    vim.cmd.edit({ args = { file } })
  end
end

return {
  "tpope/vim-fugitive",
  dependencies = { "tpope/vim-rhubarb" },
  cmd = { "GitHistory", "Git", "GBrowse", "Gwrite", "GitEditDiff", "GitEditChanged" },
  keys = {
    { "<leader>gh", "<cmd>GitHistory<CR>", desc = "[G]it [H]istory" },
    { "<leader>gb", "<cmd>Git blame<CR>", desc = "[G]it [B]lame" },
    { "<leader>gc", "<cmd>GBrowse!<CR>", desc = "[G]it [C]opy link" },
    { "<leader>gc", ":GBrowse!<CR>", mode = "v", desc = "[G]it [C]opy link" },
  },
  config = function()
    vim.cmd("command! GitHistory Git! log -- %")

    vim.api.nvim_create_user_command("GitEditChanged", function()
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

    vim.api.nvim_create_user_command("GitEditDiff", function()
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
  end,
}
