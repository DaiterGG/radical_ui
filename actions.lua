local class = require("class")
local utils = require("utils")

local actions = class()

function actions:new()
	self.actions = {}
end

function actions:register(_actions)
	if not _actions then
		return
	end
	if type(_actions) == "table" and not _actions.action then
		for _, action in ipairs(_actions) do
			self:register(action)
		end
		return
	end
	self.actions[#self.actions + 1] = _actions
end

function actions:register_with_value(_actions, value)
	if not _actions then
		return
	end

	if type(_actions) == "table" and not _actions.action then
		for _, action in ipairs(_actions) do
			self:register_with_value(action, value)
		end
		return
	end
	local temp = {}
	for key, data in pairs(_actions) do
		temp[key] = data
	end
	temp.attached = value
	self.actions[#self.actions + 1] = temp
end

function actions:pop()
	return table.remove(self.actions, 1)
end

function actions:clear()
	self.actions = {}
end

return actions
