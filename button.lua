local apply_display = require("apply_display")
local class = require("class")
local ui_element = require("ui_element")
local utils = require("utils")

-- button widget: interactive (hover/press states).
-- optionally owns a child ui_element (text or icon element, created in the
-- view and passed to the builder); the button draws it and manages its state.
-- completely independent widget file.

local button = class()
button.type = "button"

function button:new(on_press, child)
	self.on_press = on_press
	self.child = child
end

function button:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state

	-- keyed by the element's hash: several elements can be interacted with at once
	local interacting = input.interacting_with[elem.hash_num] == elem
	if hit and input.left == "pressed" then
		input.interacting_with[elem.hash_num] = elem
	elseif interacting and not (input.left == "held" or input.left == "pressed") then
		input.interacting_with[elem.hash_num] = nil
	end

	-- push the configured action into the action queue when clicked
	if self.on_press and hit and input.left == "pressed" then
		print("hi")
		ctx.action_queue:register(self.on_press)
	end
end

function button:draw(elem, ctx, widget_data, all_data)
	local r = elem.rect

	apply_display.draw_background(
		r,
		widget_data.bg,
		widget_data.border,
		all_data.polyline,
		{ scale = ctx.ui_scale or 1 }
	)

	-- draw the owned child (text/icon) on top; its state mirrors the button's
	if self.child then
		self.child.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
		self.child.states = elem.states
		self.child:draw(ctx)
	end
end

return button
