local widget_registry = {}
widget_registry.__index = widget_registry

function widget_registry.new()
	return setmetatable({}, widget_registry)
end

function widget_registry:get(key)
	return self[key]
end

function widget_registry:set(key, data)
	self[key] = data
end

function widget_registry:set_value(key, value, data)
	self[key] = self[key] or {}
	self[key][value] = data
end

return widget_registry
