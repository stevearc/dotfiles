local M = {}

function M.on_save()
  return require("agents.comments").serialize()
end

---@param data? {version?:integer, comments?:table[]}
function M.on_post_load(data)
  if type(data) == "table" and data.version == 1 then
    require("agents.comments").restore(data.comments)
    require("agents.comments").set_review_text(data.review_text or "")
  end
end

return M
