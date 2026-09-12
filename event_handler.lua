local utils = require("utils")
-- event_handler.lua: game event entry point + per-frame processing.
-- receives all input events (mouse/keyboard/wheel), feeds ctx.input_state,
-- and routes keyboard events through keybindings -> actions.

local button_names = { "left", "right", "middle", "x1", "x2" }

local event_handler = {}

-- only modifier keys are stored from the keyboard; returns true if `key` is a
-- modifier (so the caller knows not to treat it as a trigger)
local function set_modifier(mods, key, down)
	if key == "lshift" or key == "rshift" or key == "shift" then
		mods.shift = down
		return true
	elseif key == "lctrl" or key == "rctrl" or key == "ctrl" then
		mods.ctrl = down
		return true
	elseif key == "lalt" or key == "ralt" or key == "alt" then
		mods.alt = down
		return true
	elseif key == "lgui" or key == "rgui" or key == "super" then
		mods.super = down
		return true
	end
	return false
end

-- entry point: collect every game event into the queue.
-- the game reuses ONE event table for every callback (Loop:init's shared `e`),
-- so we must copy it here - otherwise every queued event would mutate into the
-- last one (e.g. everything becomes "update") before process() drains the queue.
---@param ctx table
---@param event table
function event_handler.receive(ctx, event)
	local copy = {}
	for k, v in pairs(event) do
		copy[k] = v
	end
	table.insert(ctx.event_queue, copy)
end

-- drain the queue; feeds mouse/keyboard state into ctx.input_state and routes
-- keyboard non-modifiers through keybindings -> action queue.
---@param ctx table
function event_handler.process(ctx)
	local input = ctx.input_state
	local queue = ctx.event_queue

	for i = 1, #queue do
		local event = queue[i]

		if event.name == "mousemoved" then
			-- [1]=absX, [2]=absY, [3]=relX, [4]=relY
			input.pos.x = event[1] or input.pos.x
			input.pos.y = event[2] or input.pos.y
			input.delta.x = input.delta.x + (event[3] or 0)
			input.delta.y = input.delta.y + (event[4] or 0)
		elseif event.name == "mousepressed" then
			-- [1]=button index (1..5)
			local btn = input.button_names[event[3]]
			input[btn] = "pressed"
		elseif event.name == "mousereleased" then
			-- [1]=button index (1..5)
			local btn = input.button_names[event[3]]
			input[btn] = "released"
		elseif event.name == "wheelmoved" then
			input.scroll_y = input.scroll_y + (event[2] or 0)
		elseif event.name == "keypressed" then
			-- UI key event: [2]=key, [3]=isrepeat (repeats trigger bindings too)
			local key = event[2]
			if not ctx.state.keybind_capture and not set_modifier(input.modifiers, key, true) then
				ctx.keybindings:trigger_key(ctx, key)
			end
		elseif event.name == "inputchanged" then
			-- game's normalized input: [1]=device, [2]=id, [3]=key, [4]=state (true=press)
			local key = event[3]
			if event[4] then
				local capture = ctx.state.keybind_capture
				if capture then
					ctx.keybindings:rebind(capture.action, capture.pos, key)
					ctx.state.keybind_capture = nil
				end
			else
				set_modifier(input.modifiers, key, false)
			end
		elseif event.name == "keyreleased" then
			-- UI key event: [2]=key
			set_modifier(input.modifiers, event[2], false)
		elseif event.name == "update" or event.name == "draw" or event.name == "quit" then
		-- frame events: the game loop drives the UI via update()/draw() method
		-- calls (GameController intercepts them); they only reach receive() when
		-- fed straight to it -> ignore
		elseif event.name == "textinput" then
		-- TODO: text input (text boxes)
		elseif event.name == "focus" then
		-- TODO: window focus gained/lost (event[1] = focused)
		elseif event.name == "mousefocus" then
		-- TODO: window mouse focus (event[1] = focused)
		elseif event.name == "resize" then
			local w, h = event[1], event[2]
			ctx.res.w, ctx.res.h = w, h
			ctx.ui_scale = h / 1080
			ctx.ui.need_to_realign = true
		elseif event.name == "filedropped" then
		-- TODO: dropped file (event[1] = path)
		elseif event.name == "directorydropped" then
		-- TODO: dropped directory (event[1] = path)
		elseif
			event.name == "gamepadaxis"
			or event.name == "gamepadpressed"
			or event.name == "gamepadreleased"
			or event.name == "joystickaxis"
			or event.name == "joystickpressed"
			or event.name == "joystickreleased"
		then
		-- TODO: gamepad / joystick input
		elseif event.name == "midipressed" or event.name == "midireleased" then
		-- TODO: midi input
		else
			print("UNHANDLED: ", event.name)
		end
	end

	ctx.event_queue = {}
end

return event_handler
