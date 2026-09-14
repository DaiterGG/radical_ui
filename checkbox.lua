local apply_display = require("apply_display")
local class = require("class")
local widget = require("widget")

local checkbox = class()
checkbox.type = "checkbox"

function checkbox:new(on_toggle, child, is_on)
	self.is_on = is_on
	self.on_toggle = on_toggle
	self.child = child
end

function checkbox:align(elem, ctx)
	widget.align(self, elem, ctx)
end

function checkbox:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	if hit and input.left == "pressed" then
		input.interacting_with = elem.hash_num
	end
end

function checkbox:pointer_collision_after(elem, ctx, hit, children_hit)
	local input = ctx.input_state
	local true_hit = hit and not children_hit
	if true_hit and input.left == "pressed" then
		ctx.action_queue:register(self.on_toggle)
	end
end

function checkbox:draw(elem, ctx, widget_display_data, display_data)
	local r = elem.rect
	if not r then
		return
	end

	if widget_display_data then
		local base_data = widget_display_data
		local state_data = self.is_on and base_data.on or base_data.off
		state_data = state_data or base_data
		local background_data = {
			bg = state_data.bg,
			border = state_data.border or base_data.border,
			blur = state_data.blur or base_data.blur,
			gradient = state_data.gradient or base_data.gradient,
		}
		apply_display.draw_background(background_data, ctx, r, elem.polyline, elem)
	end

	-- draw the owned child (any ui_element) on top; its state mirrors the checkbox
	if self.child then
		widget.set_child_states(self.child, elem.states)
		self.child:draw_rec(ctx)
	end
end

return checkbox
