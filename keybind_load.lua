-- keybind_load.lua: default keybindings, applied once by the UI's load().
-- modifier combos use ctrl+shift+alt+super order, e.g. "ctrl+shift+p"
local default_bindings = {
	{ key = "escape", action = "quit" },
	{ key = "t", action = "test_animation" },
	{ key = "up", action = "main_list_up" },
	{ key = "down", action = "main_list_down" },
	{ key = "ctrl+up", action = "main_list_first" },
	{ key = "ctrl+down", action = "main_list_last" },
	{ key = "left", action = "input_left" },
	{ key = "right", action = "input_right" },
	{ key = "backspace", action = "input_backspace" },
	{ key = "delete", action = "input_delete" },
	{ key = "home", action = "input_home" },
	{ key = "end", action = "input_end" },
	{ key = "ctrl+a", action = "input_select_all" },
	{ key = "ctrl+c", action = "input_copy" },
	{ key = "ctrl+x", action = "input_cut" },
	{ key = "ctrl+v", action = "input_paste" },
	{ key = "return", action = "input_deselect" },
	{ key = "kpenter", action = "input_deselect" },
}

return function(ctx)
	local kb = ctx.keybindings

	for _, binding in ipairs(default_bindings) do
		kb.keys[binding.key] = binding.action
	end
end
