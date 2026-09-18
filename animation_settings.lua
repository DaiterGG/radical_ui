local animation_settings = {}

local function get_mode(ctx)
	local mode = ctx.settings.ui_settings.animations
	if mode == nil then
		return "on"
	end
	if mode ~= "on" and mode ~= "faster" and mode ~= "instant" and mode ~= "off" then
		error("unknown animation setting: " .. tostring(mode), 3)
	end
	return mode
end

function animation_settings.duration(ctx, duration)
	local mode = get_mode(ctx)
	if mode == "faster" then
		return duration / 4
	end
	if mode == "instant" or mode == "off" then
		return 0
	end
	return duration
end

function animation_settings.is_instant(ctx)
	local mode = get_mode(ctx)
	return mode == "instant" or mode == "off"
end

function animation_settings.is_disabled(ctx)
	return get_mode(ctx) == "off"
end

return animation_settings
