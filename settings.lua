local class = require("class")

local settings = class()

local function copy_settings(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = {}
			copy_settings(target[key], value)
		else
			target[key] = value
		end
	end
end

function settings:new()
	self.default_settings = {
		game_settings = {},
		ui_settings = {
			animations_all = { "on", "faster", "instant", "off" },
			animations = "on",
			custom_scale = 1,
			dummy_value = 100,
			blur = true,
			background = true,
		},
	}
end

function settings:on_load()
	copy_settings(self, self.default_settings)
	return self
end

return settings
