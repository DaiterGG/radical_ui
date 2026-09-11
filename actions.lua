local class = require("class")

local actions = class()

function actions:new()
	self.actions = {}
end

function actions:register(data)
	self.actions[#self.actions + 1] = data
end

function actions:pop()
	return table.remove(self.actions, 1)
end

function actions:clear()
	self.actions = {}
end

return actions
