local animation_registry = {}
animation_registry.__index = animation_registry

function animation_registry.new()
	return setmetatable({}, animation_registry)
end

function animation_registry:update(animation_name, direction, force)
	local in_or_from = direction
	local stamp = love.timer.getTime()

	if in_or_from ~= "in" and in_or_from ~= "from" then
		error("animation direction must be 'in' or 'from'")
	end

	local animation = self[animation_name]
	if not animation or force then
		animation = {
			progress = 0,
			transition_stamp = stamp,
			transition_progress = force and 1 or 0,
		}
		self[animation_name] = animation
	end
	animation[in_or_from] = stamp
	return animation
end

return animation_registry
