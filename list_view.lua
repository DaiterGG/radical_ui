local class = require("class")
local apply_display = require("apply_display")
local apply_align = require("apply_align")
local ui_element = require("ui_element")
local box = require("box")

local function clamp(v, mn, mx)
	return v < mn and mn or (v > mx and mx or v)
end

-- list_view widget: scrollable vertical list of ui_elements.
-- the owning ui_element's rect is the viewport; children are stacked top to
-- bottom inside it and each child's rect is set with its align function.
-- children rects are slid up by scroll_y (screen space), so draw + collision
-- need no extra transform; the draw stencil clips anything sticking out of
-- the viewport (the rect itself is never clipped).
--
-- two scroll modes (wheel is always on):
--   1) drag the content directly
--   2) drag the scroll bar thumb
-- enabled drag modes come from the list display data:
--   drag_mode = "both" | "only_bar" | "only_drag"  (default "both")
local list_view = class()
list_view.type = "list_view"

function list_view:new(scroll_bar, bar_only)
	self.drag_mode = bar_only or false
	self.scroll_y = 0
	self.content_height = 0
	self.max_scroll_y = 0
	self.wheel_speed = 80

	self.is_dragging = false
	self.drag_start_y = 0
	self.drag_scroll_start_y = 0

	self.bar_dragging = false
	self.bar_drag_start_y = 0
	self.bar_drag_scroll_start = 0
	self.bar_travel = 0
	self.bar_track_top = 0
	self.bar_thumb_h = 0
	self.bar_hit = nil

	self.children = {}
	self.needs_realign = true

	self.scrollbar_elem = scroll_bar

	-- scrollbar_elem.align will be set to this
	self.scrollbar_align = nil
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
	self.bar_dragging = false
	self.needs_realign = true
end

-- stack every child inside the viewport; each child aligns itself inside its
-- slot window (so it can size itself: 100% width / fixed px height / block).
-- content_height = sum of the children's heights, max_scroll follows from it.
function list_view:realign(ctx, elem)
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
		child:align_rec(window, ctx)
		if child.rect then
			y = y + child.rect.h
		end
	end

	self.content_height = y - (r.y - self.scroll_y)
	self.max_scroll_y = math.max(0, self.content_height - r.h)
	self.scroll_y = clamp(self.scroll_y, 0, self.max_scroll_y)

	if self.scrollbar_elem then
		self:update_scrollbar(elem, ctx)
	end
end

-- build / refresh the scroll bar element. the bar has no align of its own:
-- the list_view constructs an absolute Align, attaches it to the element and
-- calls align_rec() with the scroll view rect so the bar (and any children)
-- can generate their rects recursively. we never set scrollbar_elem.rect.
function list_view:update_scrollbar(elem, ctx)
	local r = self.rect
	if not r or r.h <= 0 then
		return
	end

	local display_data = ctx.display_list[elem.display_key]
	local widget_data = display_data and display_data.list_view
	local sb = widget_data and widget_data.scroll_bar
	if not sb then
		return
	end

	local width = tonumber(sb.width) or 8
	local padding = tonumber(sb.padding) or 0
	if width <= 0 then
		return
	end

	local scale = ctx.ui_scale or 1
	local pad = padding * scale
	local bar_w = width * scale

	-- the scroll bar track is the viewport inset by top/bottom padding
	local track_h = r.h - pad * 2
	if track_h <= 0 then
		return
	end

	-- thumb height: full track when content fits, shrinking as content grows
	local thumb_h = track_h
	if self.content_height and self.content_height > r.h then
		thumb_h = track_h * (r.h / self.content_height)
	end
	local min_h = math.min(16 * scale, track_h)
	thumb_h = math.max(thumb_h, min_h)
	thumb_h = math.min(thumb_h, track_h)

	-- bar geometry (screen px), used by the bar drag mode + hit detection
	self.bar_travel = track_h - thumb_h
	self.bar_thumb_h = thumb_h
	self.bar_track_top = r.y + pad
	-- hit column is padding + width + padding wide on the right edge of the
	-- viewport, spanning the whole track vertically
	self.bar_hit = {
		x = r.x + r.w - pad * 2 - bar_w,
		y = r.y + pad,
		w = pad * 2 + bar_w,
		h = track_h,
	}

	-- thumb position along the track
	local y_off = pad
	if self.max_scroll_y and self.max_scroll_y > 0 then
		y_off = y_off + (self.scroll_y / self.max_scroll_y) * self.bar_travel
	end

	-- absolute align values (parent_pivot/pivot are 0..100 percentages).
	local parent_pivot = { x = 100, y = 0 }
	local pivot = {
		x = 100 + (100 * pad / bar_w),
		y = -100 * y_off / thumb_h,
	}
	local size = apply_align.Size({
		px_hor = width,
		per_vert = (thumb_h / r.h) * 100,
	})

	if not self.scrollbar_align then
		self.scrollbar_align = apply_align.Align():absolute({
			pivot = pivot,
			parent_pivot = parent_pivot,
			size = size,
		})
		self.scrollbar_elem.align = self.scrollbar_align
	else
		self.scrollbar_align.pivot.x = pivot.x
		self.scrollbar_align.pivot.y = pivot.y
		self.scrollbar_align.parent_pivot.x = parent_pivot.x
		self.scrollbar_align.parent_pivot.y = parent_pivot.y
		self.scrollbar_align.size = size
	end

	-- generate the bar rect (and its children) from the scroll view rect
	self.scrollbar_elem:align_rec({ x = r.x, y = r.y, w = r.w, h = r.h }, ctx)
end

function list_view:update_scroll(elem, ctx)
	local r = elem.rect
	if not r then
		return
	end
	self.rect = r

	-- content_height / child rects / bar rect must be fresh before input
	self:realign(ctx, elem)

	self.max_scroll_y = math.max(0, self.content_height - r.h)

	local input = ctx.input_state
	local mx = input.pos.x
	local my = input.pos.y

	local in_rect = mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h

	local old_scroll = self.scroll_y

	-- which drag interactions are enabled (wheel is always on):
	--   drag_mode: "both" | "only_bar" | "only_drag"
	local allow_bar = self.scrollbar_elem and true
	local allow_drag = not self.drag_mode

	-- wheel scroll (wheel up -> toward the top); works in both drag modes and
	-- keeps working while a drag is active even if the pointer left the viewport
	local wheel_active = in_rect
	if wheel_active and input.scroll_y and input.scroll_y ~= 0 then
		self.scroll_y = self.scroll_y - input.scroll_y * self.wheel_speed
		input.scroll_y = 0
	end

	local held = input.left == "held" or input.left == "pressed"

	-- bar hit area: a column `padding + width + padding` wide on the right
	-- edge of the viewport, spanning the whole track. when bar dragging is
	-- disabled the column does not swallow the pointer.
	local bh = self.bar_hit
	local over_bar = bh ~= nil and allow_bar and mx >= bh.x and mx < bh.x + bh.w and my >= bh.y and my < bh.y + bh.h

	-- scroll mode 2: drag the scroll bar (pressing the thumb grabs it at the
	-- grabbed point; pressing empty track jumps the thumb there first)
	if self.bar_dragging then
		if held then
			if self.bar_travel > 0 then
				self.scroll_y = self.bar_drag_scroll_start
					+ (my - self.bar_drag_start_y) * (self.max_scroll_y / self.bar_travel)
			end
		else
			self.bar_dragging = false -- button released -> stop dragging
			input.interacting_with[elem.hash_num] = nil
		end
	elseif self.max_scroll_y > 0 and over_bar and input.left == "pressed" then
		self.bar_dragging = true
		input.interacting_with[elem.hash_num] = elem

		-- where on the thumb the pointer grabbed it (0..thumb_h)
		local thumb_top = self.bar_track_top + (self.scroll_y / self.max_scroll_y) * self.bar_travel
		local grab = clamp(my - thumb_top, 0, self.bar_thumb_h)

		-- place the thumb so the grabbed point stays under the pointer
		if self.bar_travel > 0 then
			self.scroll_y =
				clamp(((my - grab - self.bar_track_top) / self.bar_travel) * self.max_scroll_y, 0, self.max_scroll_y)
		end
		self.bar_drag_start_y = my
		self.bar_drag_scroll_start = self.scroll_y
	end

	-- scroll mode 1: drag the content (not while the bar is grabbed)
	if not self.bar_dragging then
		if self.is_dragging then
			if held then
				self.scroll_y = self.drag_scroll_start_y - (my - self.drag_start_y)
			else
				self.is_dragging = false -- button released -> stop dragging
				input.interacting_with[elem.hash_num] = nil
			end
		elseif allow_drag and in_rect and not over_bar and input.left == "pressed" then
			self.is_dragging = true
			self.drag_start_y = my
			self.drag_scroll_start_y = self.scroll_y
			input.interacting_with[elem.hash_num] = elem
		end
	end

	-- clamp, then re-align children only when the scroll position moved
	self.scroll_y = clamp(self.scroll_y, 0, self.max_scroll_y)
	if self.scroll_y ~= old_scroll then
		self.needs_realign = true
	end
	self:realign(ctx, elem)
end

function list_view:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state

	-- only run the scroll state machine when something can change it: while a
	-- drag is in progress, or when this viewport is hit with a click/wheel.
	local interacting = input.interacting_with[elem.hash_num] == elem
	local active = interacting
		or self.is_dragging
		or self.bar_dragging
		or (hit and (input.left == "pressed" or input.scroll_y ~= 0))
	if active then
		self:update_scroll(elem, ctx)
	end

	-- forward every frame: the hit we got here is passed down as parent_hit,
	-- so children (and the bar) only react when an ancestor is hit. this keeps
	-- their states in sync even when the pointer is outside the viewport,
	-- exactly like ui_element:pointer_collision_rec.
	for _, child in ipairs(self.children) do
		child:pointer_collision_rec(ctx, hit)
	end
	if self.scrollbar_elem then
		self.scrollbar_elem:pointer_collision_rec(ctx, hit)
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
		r,
		widget_data and widget_data.bg,
		widget_data and widget_data.border,
		elem.polyline,
		{ scale = ctx.ui_scale or 1 }
	)

	-- children rects (and the scroll bar) must be in sync before drawing
	self:realign(ctx, elem)

	if #self.children > 0 then
		-- stencil clip to the viewport: children are already slid by scroll_y,
		-- so draw just renders them at their rects and the clip hides overflow
		love.graphics.push("all")

		love.graphics.stencil(function()
			love.graphics.rectangle("fill", math.floor(r.x + 0.5), math.floor(r.y + 0.5), r.w, r.h)
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)

		for _, child in ipairs(self.children) do
			child:draw_rec(ctx)
		end

		love.graphics.setStencilTest()
		love.graphics.pop()
	end

	-- scroll bar is drawn on top, unclipped
	if self.scrollbar_elem then
		self.scrollbar_elem:draw_rec(ctx)
	end
end

return list_view
