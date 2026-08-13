local M = {}

function M.on_save()
  return require("claude.comments").serialize()
end

---@param data? {version?:integer, comments?:table[]}
function M.on_post_load(data)
  if type(data) == "table" and data.version == 1 then
    require("claude.comments").restore(data.comments)
    require("claude.comments").set_review_text(data.review_text or "")
  end
end

return M
