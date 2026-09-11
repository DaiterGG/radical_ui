local widget_registry = {}
widget_registry.__index = widget_registry

function widget_registry.new()
	return setmetatable({}, widget_registry)
end

function widget_registry:get(key)
	return self[key]
end

function widget_registry:set(key, value)
	self[key] = value
	return value
end

return widget_registry
