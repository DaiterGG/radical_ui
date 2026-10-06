local class = require("class")

local SCROLL_SPEED = 10

local input_list = class()
input_list.type = "input_list"

function input_list:new(registry_key, children, item_gap, scroll_to)
	if registry_key == nil or children == nil or item_gap == nil or scroll_to == nil then
		error("input_list requires registry_key, children, item_gap, and scroll_to")
	end
	self.registry_key = registry_key
	self.children = children
	self.item_gap = item_gap
	self.scroll_to = scroll_to
end

function input_list:get_data(ctx)
	local data = ctx.widget_reg:get(self.registry_key)
	if not data then
		data = { y_scroll = self.scroll_to }
		ctx.widget_reg:set(self.registry_key, data)
	end
	return data
end

function input_list:align(elem, ctx)
	local rect = elem.rect
	local data = self:get_data(ctx)
	local heights = {}
	local total_height = 0
	local count = #self.children

	if count > 0 then
		self.scroll_to = math.max(1, math.min(count, self.scroll_to))
		local delta = self.scroll_to - data.y_scroll
		local step = delta * SCROLL_SPEED * math.min(ctx.state.last_delta or 0, 0.05)
		data.y_scroll = math.abs(step) >= math.abs(delta) and self.scroll_to or data.y_scroll + step
	end

	for index, child in ipairs(self.children) do
		child:align_rec({ x = rect.x, y = rect.y, w = rect.w, h = rect.h }, ctx)
		heights[index] = child.rect and child.rect.h or 0
		total_height = total_height + heights[index]
	end

	local gap = self.item_gap
	local center = rect.y + rect.h / 2
	local position = math.max(1, math.min(count, data.y_scroll))
	local item_height = heights[1] or 0
	local y = center - item_height / 2 - (position - 1) * (item_height + gap)

	for index, child in ipairs(self.children) do
		local height = heights[index]
		child:align_rec({ x = rect.x, y = y, w = rect.w, h = rect.h }, ctx)
		y = y + height + gap
	end

	if count > 0 and math.abs(self.scroll_to - data.y_scroll) > 0.001 then
		ctx.state.need_to_realign = true
	end
	data.content_height = total_height + math.max(0, #self.children - 1) * gap
end

function input_list:pointer_collision(elem, ctx, hit)
	for _, child in ipairs(self.children) do
		child:pointer_collision_rec(ctx, hit)
	end
end

function input_list:draw(elem, ctx)
	local rect = elem.rect
	love.graphics.push("all")
	love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
	for _, child in ipairs(self.children) do
		if child.rect and child.rect.y + child.rect.h >= rect.y and child.rect.y <= rect.y + rect.h then
			child:draw_rec(ctx)
		end
	end
	love.graphics.pop()
end

return input_list
