local M = {}

local default_config = {
  on_attach = nil,
}

local config = {}

M.setup = function(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
  vim.cmd([[
    augroup TagAttach
      au!
      autocmd FileType * call luaeval('require("tags")._try_attach(tonumber(_A))', expand('<abuf>'))
    augroup END
    ]])
end

M._try_attach = function(bufnr)
  local tagfiles = vim.fn.tagfiles()
  if #tagfiles == 0 then
    return
  end
  local attached = pcall(vim.api.nvim_buf_get_var, bufnr, "tags_attached")
  if attached then
    return
  end
  if config.on_attach then
    config.on_attach(bufnr)
  end
  vim.api.nvim_buf_set_var(bufnr, "tags_attached", true)
end

local function jump_to(word, candidates)
  if #candidates == 0 then
    vim.notify(string.format("No tag found for '%s'", word), vim.log.levels.WARN)
  elseif #candidates == 1 then
    vim.cmd(string.format("tag %s", word))
  else
    vim.ui.select(candidates, {
      prompt = string.format("Jump to %s", word),
      format_item = function(item)
        local cmd = string.gsub(item.cmd, "^/%^", "")
        cmd = string.gsub(cmd, "%$/$", "")
        return string.format("%s: %s", item.filename, cmd)
      end,
      kind = "tag",
    }, function(_, idx)
      if idx then
        vim.cmd(string.format("%dtag %s", idx, word))
      end
    end)
  end
end

local function make_exact(word)
  local ret = word
  if string.find(word, "%^") ~= 1 then
    ret = "^" .. ret
  end
  if not string.find(word, "%$", #word - 1) then
    ret = ret .. "$"
  end
  return ret
end

M.goto_definition = function(word, opts)
  word = word or vim.fn.expand("<cword>")
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    match = "smart",
  })
  local candidates
  if opts.match == "smart" then
    local term = make_exact(word)
    if term ~= word then
      candidates = vim.fn.taglist(term)
      if #candidates > 0 then
        jump_to(word, candidates)
        return
      end
    end
    jump_to(word, vim.fn.taglist(word))
  elseif opts.match == "exact" then
    jump_to(word, vim.fn.taglist(make_exact(word)))
  elseif opts.match == "raw" then
    jump_to(word, vim.fn.taglist(word))
  else
    vim.notify(string.format("Unknown match type '%s'", opts.match), vim.log.levels.ERROR)
  end
end

return M
