local apply_display = require("apply_display")
local class = require("class")
local widget = require("widget")

local slider = class()
slider.type = "slider"

function slider:new(value, child, on_drag, on_release)
	self.value = value
	self.child = child
	self.on_drag = on_drag
	self.on_release = on_release
end

function slider:ratio()
	if self.value.max == self.value.min then
		return 0
	end
	return math.max(0, math.min(1, (self.value.current - self.value.min) / (self.value.max - self.value.min)))
end

function slider:align(elem, ctx)
	if not self.child then
		return
	end
	local r = elem.rect
	local window = {
		x = r.x,
		y = r.y,
		w = r.w,
		h = r.h,
	}
	self.child.rect = window
	self.child:align_rec(window, ctx)
	self.child.rect.x = r.x + (r.w - self.child.rect.w) * self:ratio()
end

function slider:pointer_collision(elem, ctx, hit)
	if hit and ctx.input_state.left == "pressed" then
		ctx.input_state.interacting_with = elem.hash_num
	end
end

function slider:pointer_collision_after(elem, ctx, hit)
	local input = ctx.input_state
	local interacting = input.interacting_with == elem.hash_num
	if input.left == "pressed" or input.left == "held" then
		if not interacting and not hit then
			return
		end
		local r = elem.rect
		local ratio = math.max(0, math.min(1, (input.pos.x - r.x) / r.w))
		self.value.current = self.value.min + (self.value.max - self.value.min) * ratio
		ctx.action_queue:register_with_value(self.on_drag, self.value.current)
		ctx.ui.need_to_realign = true
	elseif input.left == "released" then
		if interacting then
			ctx.action_queue:register_with_value(self.on_release, self.value.current)
			input.interacting_with = nil
		end
	end
end

function slider:draw(elem, ctx, widget_display_data)
	if widget_display_data then
		apply_display.draw_background(widget_display_data, ctx, elem.rect, elem.polyline, elem)
	end
	if self.child then
		widget.set_child_states(self.child, elem.states)
		self.child:draw_rec(ctx)
	end
end

return slider
