local M = {}

local function create_module(list_type, getlist)
  local submod = {}

  ---Get the number of lists in the stack
  ---@return integer
  submod.stack_count = function()
    return getlist({ nr = "$" }).nr
  end

  ---Get all lists in the stack
  ---@param props nil|string[] List of properties to fetch (see :help getflist())
  ---@return table[]
  submod.get_stack = function(props)
    if not props then
      props = { "id", "idx", "title", "context", "size" }
    end
    local opts = {}
    for _, prop in ipairs(props) do
      opts[prop] = 0
    end
    local num = submod.stack_count()
    local ret = {}
    for i = num, 1, -1 do
      opts.nr = i
      table.insert(ret, getlist(opts))
    end
    return ret
  end

  ---Choose a list from the stack
  ---@param opts table See :help vim.ui.select
  ---@param callback fun(list: nil|table)
  submod.select = function(opts, callback)
    opts = vim.tbl_deep_extend("keep", opts or {}, {
      prompt = "Select list",
      format_item = function(qf)
        return qf.title
      end,
    })
    local stack = submod.get_stack()
    vim.ui.select(stack, opts, callback)
  end

  submod.set_list = function(id)
    if not id then
      submod.select({ prompt = string.format("%s list", list_type) }, function(qf)
        if qf then
          submod.set_list(qf.id)
        end
      end)
      return
    end
    local target = getlist({ id = id, nr = 0 }).nr
    local current = getlist({ nr = 0 }).nr
    local diff = target - current
    local cmd
    if diff == 0 then
      return
    elseif diff < 0 then
      cmd = "colder"
      diff = -1 * diff
    else
      cmd = "cnewer"
    end
    vim.cmd(string.format("%s %s", cmd, diff))
  end

  return submod
end

M.qf = create_module("quickfix", vim.fn.getqflist)

M.ll = setmetatable(
  create_module("location", function(...)
    return vim.fn.getloclist(0, ...)
  end),
  {
    __index = function(_, winid)
      return create_module("location", function(...)
        return vim.fn.getloclist(winid, ...)
      end)
    end,
  }
)

return M
