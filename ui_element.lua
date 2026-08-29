local class = require("class")

local ui_element = class()

function ui_element:new(display_data)
  local data = display_data or {}
  self.display_id = data.display_id or ""
  self.style = data.style or {}
  self.list_id = {}
  self.type = {}
  self.align = {}
  self.children = {}
end

function ui_element:push_child(child)
  self.children[#self.children + 1] = child
end

return ui_element
