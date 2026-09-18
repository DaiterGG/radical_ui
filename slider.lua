local apply_display = require("apply_display")
local class = require("class")
local widget = require("widget")

local slider = class()
slider.type = "slider"

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

function slider:new(value, child, on_drag, on_release, on_hield)
	self.value = value
	self.child = child
	self.on_drag = on_drag
	self.on_release = on_release
	self.on_hield = on_hield
end

function slider:get_child(elem)
	if elem.states.held and self.on_hield then
		return self.on_hield
	end
	return self.child
end

function slider:ratio()
	if self.value.max == self.value.min then
		return 0
	end
	return math.max(0, math.min(1, (self.value.current - self.value.min) / (self.value.max - self.value.min)))
end

function slider:rebuild(element)
	for _, current_widget in ipairs(element.widget) do
		if current_widget.type == "text" then
			current_widget.text = string.format("%.1f", self.value.current)
		end
	end
	for _, child in ipairs(element.children) do
		self:rebuild(child)
	end
end

function slider:align(elem, ctx)
	local child = self:get_child(elem)
	if not child then
		return
	end
	self:rebuild(child)
	local r = elem.rect
	local window = {
		x = r.x,
		y = r.y,
		w = r.w,
		h = r.h,
	}
	child.rect = window
	child:align_rec(window, ctx)
	child.rect.x = r.x + (r.w - child.rect.w) * self:ratio()
end

function slider:pointer_collision(elem, ctx, hit)
	if hit and ctx.input_state.left == "pressed" then
		ctx.input_state.interacting_with = elem.hash_num
		ctx.state.cursor_hidden = true
		love.mouse.setVisible(false)
	end
end

function slider:pointer_collision_after(elem, ctx, hit)
	local input = ctx.input_state
	local interacting = input.interacting_with == elem.hash_num
	elem.states.held = interacting
	if input.left == "pressed" or (input.left == "held" and interacting) then
		if not interacting and not hit then
			return
		end
		local r = elem.rect
		local cursor_x = clamp(input.pos.x, r.x, r.x + r.w)
		input.pos.x = cursor_x
		love.mouse.setPosition(cursor_x, input.pos.y)
		local ratio = clamp((cursor_x - r.x) / r.w, 0, 1)
		self.value.current = self.value.min + (self.value.max - self.value.min) * ratio
		ctx.action_queue:register_with_value(self.on_drag, self.value.current)
		ctx.state.need_to_realign = true
	elseif input.left == "released" then
		if interacting then
			ctx.action_queue:register_with_value(self.on_release, self.value.current)
			input.interacting_with = nil
			ctx.state.cursor_hidden = false
			love.mouse.setVisible(true)
		end
	end
end

function slider:draw(elem, ctx, widget_display_data)
	if widget_display_data then
		apply_display.draw_background(widget_display_data, ctx, elem.rect, elem.polyline, elem)
	end
	local child = self:get_child(elem)
	if child then
		widget.set_child_states(child, elem.states)
		child:draw_rec(ctx)
	end
end

return slider
