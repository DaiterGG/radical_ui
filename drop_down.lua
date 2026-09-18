local class = require("class")

local drop_down = class()
drop_down.type = "drop_down"

local function get_widget_data(ctx, widget_key)
	local data = ctx.widget_reg:get(widget_key)
	if not data then
		data = { selected = false }
		ctx.widget_reg:set(widget_key, data)
	end
	return data
end

function drop_down:new(widget_key, idle, focused)
	if not widget_key then
		error("drop_down requires a widget registry key")
	end
	self.idle = idle
	self.focused = focused
	self.widget_key = widget_key
	self.selected_registered = false
end

function drop_down:selected_element(ctx)
	local data = get_widget_data(ctx, self.widget_key)
	if data.selected then
		return self.focused
	end
	return self.idle
end

function drop_down:align(elem, ctx)
	local data = get_widget_data(ctx, self.widget_key)
	local rect = elem.rect
	if self.idle and not data.selected then
		self.idle:align_rec({ x = rect.x, y = rect.y, w = rect.w, h = rect.h }, ctx)
		return
	end
	if not self.focused or not data.selected then
		return
	end
	self.focused.align = self.focused.align or self.stealed_align
	self.focused:align_rec({ x = rect.x, y = rect.y, w = rect.w, h = rect.h }, ctx)
	self.stealed_align = self.focused.align
	self.focused.align = nil
	if not self.selected_registered then
		ctx.state.root_elements[#ctx.state.root_elements + 1] = self.focused
		self.selected_registered = true
	end
end

function drop_down:pointer_collision(elem, ctx)
	local data = get_widget_data(ctx, self.widget_key)

	if self.idle and not data.selected then
		local hit = self.idle:pointer_collision_rec(ctx, true)
		if hit and ctx.input_state.left == "pressed" then
			data.selected = true
			ctx.state.need_to_realign = true
		end
		return
	end
	if not data.selected then
		return
	end

	if ctx.input_state.left == "pressed" then
		data.selected = false
		ctx.state.need_to_rebuild = true
	end
end

function drop_down:draw(elem, ctx)
	local data = get_widget_data(ctx, self.widget_key)
	if self.idle and not data.selected then
		self.idle:draw_rec(ctx)
	end
end

return drop_down
