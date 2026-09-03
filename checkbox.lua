local apply_display = require("apply_display")
local class = require("class")
local ui_element = require("ui_element")
local utils = require("utils")

-- button widget: interactive (hover/press states).
-- optionally owns a child ui_element (text or icon element, created in the
-- view and passed to the builder); the button draws it and manages its state.
-- completely independent widget file.

local chekbox = class()
chekbox.type = "checkbox"

function chekbox:new(on_press, is_on, child_on, child_off)
	self.on_press = on_press
	self.child_on = child_on or nil
	self.child_off = child_off or nil
	self.is_on = is_on or false
end

function chekbox:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state

	-- push the configured action into the action queue when clicked
	if hit and input.left == "pressed" then
		self.is_on = not self.is_on
		if self.on_press then
			ctx.action_queue:register(self.on_press, { state = self.is_on })
		end
	end
end

function chekbox:draw(elem, ctx, widget_data, entry)
	local r = elem.rect
	if not widget_data then
		return
	end

	apply_display.draw_background(
		r,
		widget_data.bg,
		widget_data.border,
		entry and entry.polyline,
		{ scale = ctx.ui_scale or 1 }
	)

	if self.child_off and not self.is_on then
		self.child_off.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
		self.child_off.states = elem.states
		self.child_off:draw(ctx)
	end
	-- draw the owned child (text/icon) on top; its state mirrors the button's
	if self.child_on and self.is_on then
		self.child_on.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
		self.child_on.states = elem.states
		self.child_on:draw(ctx)
	end
end

return chekbox
