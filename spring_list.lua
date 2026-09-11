local class = require("class")
local apply_display = require("apply_display")

local function clamp(value, minimum, maximum)
	return value < minimum and minimum or (value > maximum and maximum or value)
end

local spring_list = class()
spring_list.type = "spring_list"

function spring_list:new()
	self.children = {}
end

function spring_list:get_data(ctx)
	local data = ctx.beatmaps.spring_list_data
	if not data then
		data = {
			scroll_y = 0,
			content_height = 0,
			max_scroll_y = 0,
			wheel_speed = 80,
			is_dragging = false,
			drag_start_y = 0,
			drag_scroll_start_y = 0,
			spring_velocity = 0,
			springing = false,
			middle_scrolling = false,
			middle_anchor_y = 0,
		}
		ctx.beatmaps.spring_list_data = data
	end
	return data
end

function spring_list:add_child(child)
	table.insert(self.children, child)
end

function spring_list:remove_child(child)
	for i, current in ipairs(self.children) do
		if current == child then
			table.remove(self.children, i)
			break
		end
	end
end

function spring_list:clear()
	self.children = {}
end

function spring_list:realign(ctx, elem)
	local data = self:get_data(ctx)
	local rect = elem.rect
	local y = rect.y - data.scroll_y

	for _, child in ipairs(self.children) do
		child:align_rec({ x = rect.x, y = y, w = rect.w, h = rect.h }, ctx)
		if child.rect then
			y = y + child.rect.h
		end
	end

	data.content_height = y - (rect.y - data.scroll_y)
	data.max_scroll_y = math.max(0, data.content_height - rect.h)
end

function spring_list:update_scroll(elem, ctx)
	local data = self:get_data(ctx)
	local rect = elem.rect
	local input = ctx.input_state
	local mouse_x = input.pos.x
	local mouse_y = input.pos.y
	local inside = mouse_x >= rect.x
		and mouse_x < rect.x + rect.w
		and mouse_y >= rect.y
		and mouse_y < rect.y + rect.h
	local old_scroll = data.scroll_y
	local dt = math.min(ctx.dt or 0, 0.05)

	data.max_scroll_y = math.max(0, data.content_height - rect.h)

	local function start_spring()
		if data.scroll_y < 0 or data.scroll_y > data.max_scroll_y then
			data.springing = true
		end
	end

	local function spring_to_limit()
		if not data.springing then
			return
		end
		local target = clamp(data.scroll_y, 0, data.max_scroll_y)
		local displacement = target - data.scroll_y
		data.spring_velocity = data.spring_velocity + displacement * 70 * dt
		data.spring_velocity = data.spring_velocity * math.exp(-14 * dt)
		data.scroll_y = data.scroll_y + data.spring_velocity * dt
		if math.abs(target - data.scroll_y) < 0.1 and math.abs(data.spring_velocity) < 0.1 then
			data.scroll_y = target
			data.spring_velocity = 0
			data.springing = false
		end
	end

	local middle_held = input.middle == "held" or input.middle == "pressed"
	if data.middle_scrolling then
		if middle_held then
			local distance = mouse_y - data.middle_anchor_y
			local dead_zone = 4
			if math.abs(distance) > dead_zone then
				local direction = distance < 0 and -1 or 1
				data.scroll_y = data.scroll_y + direction * (math.abs(distance) - dead_zone) * 5 * dt
			end
		else
			data.middle_scrolling = false
			input.interacting_with = nil
			if ctx.cursor then
				ctx.cursor:set_state("idle")
			end
			start_spring()
		end
	elseif inside and input.middle == "pressed" then
		data.middle_scrolling = true
		data.middle_anchor_y = mouse_y
		data.springing = false
		data.spring_velocity = 0
		if ctx.cursor then
			ctx.cursor:set_state("scroll")
		end
		input.interacting_with = elem
	end

	if inside and input.scroll_y and input.scroll_y ~= 0 then
		data.scroll_y = data.scroll_y - input.scroll_y * data.wheel_speed
		input.scroll_y = 0
		start_spring()
	end

	local held = input.left == "held" or input.left == "pressed"
	if data.is_dragging then
		if held then
			data.scroll_y = data.drag_scroll_start_y - (mouse_y - data.drag_start_y)
		else
			data.is_dragging = false
			input.interacting_with = nil
			start_spring()
		end
	elseif not data.middle_scrolling and inside and input.left == "pressed" then
		data.is_dragging = true
		data.drag_start_y = mouse_y
		data.drag_scroll_start_y = data.scroll_y
		input.interacting_with = elem
	end

	if not data.is_dragging and not data.middle_scrolling then
		spring_to_limit()
	end
	return data.scroll_y ~= old_scroll
end

function spring_list:align(elem, ctx)
	self:realign(ctx, elem)
end

function spring_list:pointer_collision(elem, ctx, hit)
	local data = self:get_data(ctx)
	local input = ctx.input_state
	if not elem.rect then
		return
	end
	local active = input.interacting_with == elem
		or data.is_dragging
		or data.middle_scrolling
		or data.springing
		or (hit and (input.left == "pressed" or input.middle == "pressed" or input.scroll_y ~= 0))
	if active and self:update_scroll(elem, ctx) then
		self:realign(ctx, elem)
	end
	for _, child in ipairs(self.children) do
		child:pointer_collision_rec(ctx, hit)
	end
end

function spring_list:draw(elem, ctx, widget_data)
	local rect = elem.rect
	apply_display.draw_background(
		rect,
		widget_data and widget_data.bg,
		widget_data and widget_data.border,
		elem.polyline,
		{ scale = ctx.ui_scale or 1 }
	)
	if #self.children == 0 then
		return
	end

	love.graphics.push("all")
	love.graphics.stencil(function()
		love.graphics.rectangle("fill", math.floor(rect.x + 0.5), math.floor(rect.y + 0.5), rect.w + 1, rect.h)
	end, "replace", 1)
	love.graphics.setStencilTest("greater", 0)
	for _, child in ipairs(self.children) do
		if not child.rect or child.rect.y > ctx.res.h then
			break
		end
		if child.rect.y + child.rect.h > 0 then
			child:draw_rec(ctx)
		end
	end
	love.graphics.setStencilTest()
	love.graphics.pop()
end

return spring_list
