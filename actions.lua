local class = require("class")
local utils = require("utils")

local actions = class()

function actions:new()
	self.actions = {}
end

function actions:register(data)
	if type(data) == "table" and not data.action then
		for _, action in ipairs(data) do
			self:register(action)
		end
		return
	end
	self.actions[#self.actions + 1] = data
end

function actions:pop()
	return table.remove(self.actions, 1)
end

function actions:clear()
	self.actions = {}
end

return actions
