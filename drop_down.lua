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
end

function drop_down:selected_element(ctx)
	local data = get_widget_data(ctx, self.widget_key)
	if data.selected then
		return self.focused
	end
	return self.idle
end

function drop_down:align(elem, ctx)
	local child = self:selected_element(ctx)
	if not child then
		return
	end
	local rect = elem.rect
	child:align_rec(
		{ x = rect.x, y = rect.y, w = rect.w, h = rect.h },
		ctx
	)
end

function drop_down:pointer_collision(elem, ctx)
	local child = self:selected_element(ctx)
	if not child then
		return
	end
	local hit = child:pointer_collision_rec(ctx, true)
	if hit and ctx.input_state.left == "pressed" then
		local data = get_widget_data(ctx, self.widget_key)
		data.selected = not data.selected
	end
end

function drop_down:draw(elem, ctx)
	local child = self:selected_element(ctx)
	if not child then
		return
	end
	child:draw_rec(ctx)
end

return drop_down
