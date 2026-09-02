local class = require("class")
local apply_display = require("apply_display")

local function clamp(v, mn, mx)
	return v < mn and mn or (v > mx and mx or v)
end

-- list_view widget: scrollable vertical list of ui_elements.
-- the owning ui_element's rect is the viewport; children are stacked top to
-- bottom inside it and each child's rect is set with its align function.
-- children rects are slid up by scroll_y (screen space), so draw + collision
-- need no extra transform; the draw stencil clips anything sticking out of
-- the viewport (the rect itself is never clipped).
local list_view = class()
list_view.type = "list_view"

function list_view:new()
	self.scroll_y = 0
	self.content_height = 0
	self.max_scroll_y = 0
	self.wheel_speed = 80

	self.is_dragging = false
	self.drag_start_y = 0
	self.drag_scroll_start_y = 0

	self.children = {}
	self.needs_realign = true
end

-- add a child element; its rect gets set (via its align) on the next realign
-- (the viewport rect is only known once the owning ui_element is aligned)
function list_view:add_child(child)
	table.insert(self.children, child)
	self.needs_realign = true
end

function list_view:remove_child(child)
	for i, c in ipairs(self.children) do
		if c == child then
			table.remove(self.children, i)
			break
		end
	end
	self.needs_realign = true
end

function list_view:clear()
	self.children = {}
	self.content_height = 0
	self.max_scroll_y = 0
	self.scroll_y = 0
	self.is_dragging = false
	self.needs_realign = true
end

-- stack every child inside the viewport; each child aligns itself inside its
-- slot window (so it can size itself: 100% width / fixed px height / block).
-- content_height = sum of the children's heights, max_scroll follows from it.
function list_view:realign(ctx)
	local r = self.rect
	if not r then
		self.content_height = 0
		self.max_scroll_y = 0
		return -- no viewport yet; stay dirty
	end
	if not self.needs_realign then
		return
	end
	self.needs_realign = false

	local y = r.y - self.scroll_y
	for _, child in ipairs(self.children) do
		local window = { x = r.x, y = y, w = r.w, h = r.h }
		if child.align_rec then
			child:align_rec(window, ctx)
		elseif child.align then
			child.rect = child.align:apply(window, ctx.ui_scale)
		else
			child.rect = { x = r.x, y = y, w = r.w, h = r.h }
		end
		if child.rect then
			y = y + child.rect.h
		end
	end

	self.content_height = y - (r.y - self.scroll_y)
	self.max_scroll_y = math.max(0, self.content_height - r.h)
	self.scroll_y = clamp(self.scroll_y, 0, self.max_scroll_y)
end

function list_view:update_scroll(elem, ctx)
	local r = elem.rect
	if not r then
		return
	end
	self.rect = r

	-- content_height / child rects must be fresh before clamping scroll
	self:realign(ctx)

	self.max_scroll_y = math.max(0, self.content_height - r.h)

	local input = ctx.input_state
	local mx = input.pos.x
	local my = input.pos.y

	local in_rect = mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h

	local old_scroll = self.scroll_y

	-- wheel scroll (wheel up -> toward the top)
	if in_rect and input.scroll_y and input.scroll_y ~= 0 then
		self.scroll_y = self.scroll_y - input.scroll_y * self.wheel_speed
		input.scroll_y = 0
	end

	-- drag scroll: grab the content and pull it (drag up -> scroll down)
	local held = input.left == "held" or input.left == "pressed"
	if self.is_dragging then
		if held then
			self.scroll_y = self.drag_scroll_start_y - (my - self.drag_start_y)
		else
			self.is_dragging = false -- button released -> stop dragging
			input.interacting_with[elem.hash_num] = nil
		end
	elseif in_rect and input.left == "pressed" then
		self.is_dragging = true
		self.drag_start_y = my
		self.drag_scroll_start_y = self.scroll_y
		input.interacting_with[elem.hash_num] = elem
	end

	-- clamp, then re-align children only when the scroll position moved
	self.scroll_y = clamp(self.scroll_y, 0, self.max_scroll_y)
	if self.scroll_y ~= old_scroll then
		self.needs_realign = true
	end
	self:realign(ctx)
end

function list_view:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state

	-- only touch alignment/scroll when something can change it; otherwise the
	-- list is static (children keep their last aligned rects):
	--   active when interacting (in the map) or hit with a click/wheel
	local interacting = input.interacting_with[elem.hash_num] == elem
	local active = interacting
		or (hit and (input.left == "pressed" or input.scroll_y ~= 0))
	if active then
		self:update_scroll(elem, ctx)
	end

	if hit then
		for _, child in ipairs(self.children) do
			if child.pointer_collision_rec then
				child:pointer_collision_rec(ctx, hit)
			elseif child.pointer_collision then
				child:pointer_collision(ctx, hit)
			end
		end
	end
end

function list_view:draw(elem, ctx, widget_data, display_data)
	local r = elem.rect
	if not r then
		return
	end
	self.rect = r

	-- background
	apply_display.draw_background(
		r.x, r.y, r.w, r.h,
		widget_data and widget_data.bg,
		widget_data and widget_data.border,
		display_data and display_data.polyline,
		{ scale = ctx.ui_scale or 1 }
	)

	-- children rects must be in sync (add/remove/scroll) before drawing
	self:realign(ctx)

	if #self.children == 0 then
		return
	end

	-- stencil clip to the viewport: children are already slid by scroll_y,
	-- so draw just renders them at their rects and the clip hides overflow
	love.graphics.push("all")

	love.graphics.stencil(function()
		love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
	end, "replace", 1)
	love.graphics.setStencilTest("greater", 0)

	for _, child in ipairs(self.children) do
		if child.draw_rec then
			child:draw_rec(ctx)
		elseif child.draw then
			child:draw(ctx)
		end
	end

	love.graphics.setStencilTest()
	love.graphics.pop()
end

return list_view
