local M = {}

M.get_static_source = function(words, kind)
  local get_completion_items = function(prefix)
    local complete_items = {}
    for _, word in ipairs(words) do
      if word:find(prefix) == 1 then
        table.insert(complete_items, {dup = 0, empty = 0, icase = 0, kind = kind or 'keyword', word = word})
      end
    end
    return complete_items
  end
  return get_completion_items
end

return M
