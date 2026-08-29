local class = require("class")

local actions = class()

function actions:new()
  self.actions = {}
end

function actions:register(action, data)
  local entry = { action = action }
  if type(data) == "table" then
    for k, v in pairs(data) do
      entry[k] = v
    end
  end
  self.actions[#self.actions + 1] = entry
  return entry
end

function actions:pop()
  return table.remove(self.actions, 1)
end

function actions:clear()
  self.actions = {}
end

return actions
