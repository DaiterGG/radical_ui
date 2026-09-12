-- keybind_load.lua: default keybindings, applied once by the UI's load().
-- modifier combos use ctrl+shift+alt+super order, e.g. "ctrl+shift+p"
local default_bindings = {
	{ key = "escape", action = "quit" },
	{ key = "t", action = "test_animation" },
	{ key = "up", action = "main_list_up" },
	{ key = "down", action = "main_list_down" },
	{ key = "ctrl+up", action = "main_list_first" },
	{ key = "ctrl+down", action = "main_list_last" },
}

return function(ctx)
	local kb = ctx.keybindings

	for _, binding in ipairs(default_bindings) do
		kb.keys[binding.key] = binding.action
	end
end
