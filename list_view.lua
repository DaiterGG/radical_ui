local class = require("class")
local utils = require("utils")
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
	self.registry_key = scroll_bar
	self.scrollbar_elem = bar_only
	self.drag_mode = select(3, ...)

	self.children = {}
end

function list_view:get_data(ctx)
	if not self.registry_key then
		error("list_view requires a widget registry key")
	end

	local data = ctx.widget_reg:get(self.registry_key)
	if not data then
		data = {
			scroll_y = 0,
			content_height = 0,
			max_scroll_y = 0,
			wheel_speed = 80,
			is_dragging = false,
			drag_start_y = 0,
			drag_scroll_start_y = 0,
			bar_dragging = false,
			bar_drag_start_y = 0,
			bar_drag_scroll_start = 0,
			bar_travel = 0,
			bar_track_top = 0,
			bar_thumb_h = 0,
			bar_hit = nil,
			scrollbar_align = nil,
		}
		ctx.widget_reg:set(self.registry_key, data)
	end
	return data
end

-- add a child element; its rect gets set (via its align) on the next realign
-- (the viewport rect is only known once the owning ui_element is aligned)
function list_view:add_child(child)
	table.insert(self.children, child)
end

function list_view:remove_child(child)
	for i, c in ipairs(self.children) do
		if c == child then
			table.remove(self.children, i)
			break
		end
	end
end

function list_view:clear()
	self.children = {}
end

-- stack every child inside the viewport; each child aligns itself inside its
-- slot window (so it can size itself: 100% width / fixed px height / block).
-- content_height = sum of the children's heights, max_scroll follows from it.
function list_view:realign(ctx, elem)
	local data = self:get_data(ctx)
	local r = elem.rect

	local y = r.y - data.scroll_y
	for _, child in ipairs(self.children) do
		local window = { x = r.x, y = y, w = r.w, h = r.h }
		child:align_rec(window, ctx)
		if child.rect then
			y = y + child.rect.h
		end
	end

	data.content_height = y - (r.y - data.scroll_y)
	data.max_scroll_y = math.max(0, data.content_height - r.h)
	data.scroll_y = clamp(data.scroll_y, 0, data.max_scroll_y)

	if self.scrollbar_elem then
		self:update_scrollbar(elem, ctx)
	end
end

-- build / refresh the scroll bar element. the bar has no align of its own:
-- the list_view constructs an absolute Align, attaches it to the element and
-- calls align_rec() with the scroll view rect so the bar (and any children)
-- can generate their rects recursively. we never set scrollbar_elem.rect.
function list_view:update_scrollbar(elem, ctx)
	local data = self:get_data(ctx)
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
	data.bar_travel = track_h - thumb_h
	data.bar_thumb_h = thumb_h
	data.bar_track_top = r.y + pad
	-- hit column is padding + width + padding wide on the right edge of the
	-- viewport, spanning the whole track vertically
	data.bar_hit = {
		x = r.x + r.w - pad * 2 - bar_w,
		y = r.y + pad,
		w = pad * 2 + bar_w,
		h = track_h,
	}

	-- thumb position along the track
	local y_off = pad
	if data.max_scroll_y and data.max_scroll_y > 0 then
		y_off = y_off + (data.scroll_y / data.max_scroll_y) * data.bar_travel
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

	if not data.scrollbar_align then
		data.scrollbar_align = apply_align.Align():absolute({
			pivot = pivot,
			parent_pivot = parent_pivot,
			size = size,
		})
		self.scrollbar_elem.align = data.scrollbar_align
	else
		data.scrollbar_align.pivot.x = pivot.x
		data.scrollbar_align.pivot.y = pivot.y
		data.scrollbar_align.parent_pivot.x = parent_pivot.x
		data.scrollbar_align.parent_pivot.y = parent_pivot.y
		data.scrollbar_align.size = size
	end

	-- generate the bar rect (and its children) from the scroll view rect
	self.scrollbar_elem:align_rec({ x = r.x, y = r.y, w = r.w, h = r.h }, ctx)
end

function list_view:update_scroll(elem, ctx)
	local data = self:get_data(ctx)
	local r = elem.rect

	data.max_scroll_y = math.max(0, data.content_height - r.h)

	local input = ctx.input_state
	local mx = input.pos.x
	local my = input.pos.y

	local in_rect = mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h

	local old_scroll = data.scroll_y

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
	local bh = data.bar_hit
	local over_bar = bh ~= nil and allow_bar and mx >= bh.x and mx < bh.x + bh.w and my >= bh.y and my < bh.y + bh.h

	-- scroll mode 2: drag the scroll bar (pressing the thumb grabs it at the
	-- grabbed point; pressing empty track jumps the thumb there first)
	if data.bar_dragging then
		if held then
			if data.bar_travel > 0 then
				data.scroll_y = data.bar_drag_scroll_start
					+ (my - data.bar_drag_start_y) * (data.max_scroll_y / data.bar_travel)
			end
		else
			data.bar_dragging = false -- button released -> stop dragging
			input.interacting_with = nil
		end
	elseif data.max_scroll_y > 0 and over_bar and input.left == "pressed" then
		data.bar_dragging = true
		input.interacting_with = elem

		-- where on the thumb the pointer grabbed it (0..thumb_h)
		local thumb_top = data.bar_track_top + (data.scroll_y / data.max_scroll_y) * data.bar_travel
		local grab = clamp(my - thumb_top, 0, data.bar_thumb_h)

		-- place the thumb so the grabbed point stays under the pointer
		if data.bar_travel > 0 then
			data.scroll_y =
				clamp(((my - grab - data.bar_track_top) / data.bar_travel) * data.max_scroll_y, 0, data.max_scroll_y)
		end
		data.bar_drag_start_y = my
		data.bar_drag_scroll_start = data.scroll_y
	end

	-- scroll mode 1: drag the content (not while the bar is grabbed)
	if not data.bar_dragging then
		if data.is_dragging then
			if held then
				data.scroll_y = data.drag_scroll_start_y - (my - data.drag_start_y)
			else
				data.is_dragging = false -- button released -> stop dragging
				input.interacting_with = nil
			end
		elseif allow_drag and in_rect and not over_bar and input.left == "pressed" then
			data.is_dragging = true
			data.drag_start_y = my
			data.drag_scroll_start_y = data.scroll_y
			input.interacting_with = elem
		end
	end

	-- clamp, then re-align children only when the scroll position moved
	data.scroll_y = clamp(data.scroll_y, 0, data.max_scroll_y)
	if data.scroll_y ~= old_scroll then
		return true
	end
	return false
end

function list_view:align(elem, ctx)
	self:realign(ctx, elem)
end
function list_view:pointer_collision(elem, ctx, hit)
	local data = self:get_data(ctx)
	local input = ctx.input_state
	if elem.rect == nil then
		return
	end

	-- only run the scroll state machine when something can change it: while a
	-- drag is in progress, or when this viewport is hit with a click/wheel.
	local interacting = input.interacting_with == elem
	local active = interacting
		or data.is_dragging
		or data.bar_dragging
		or (hit and (input.left == "pressed" or input.scroll_y ~= 0))
	if active then
		if self:update_scroll(elem, ctx) then
			self:realign(ctx, elem)
		end
	end

	for _, child in ipairs(self.children) do
		child:pointer_collision_rec(ctx, hit)
	end
	if self.scrollbar_elem then
		self.scrollbar_elem:pointer_collision_rec(ctx, hit)
	end
end

function list_view:draw(elem, ctx, widget_data, display_data)
	local r = elem.rect

	-- background
	apply_display.draw_background(
		r,
		widget_data and widget_data.bg,
		widget_data and widget_data.border,
		elem.polyline,
		{ scale = ctx.ui_scale or 1 }
	)

	if #self.children > 0 then
		-- stencil clip to the viewport: children are already slid by scroll_y,
		-- so draw just renders them at their rects and the clip hides overflow
		love.graphics.push("all")

		love.graphics.stencil(function()
			love.graphics.rectangle("fill", math.floor(r.x + 0.5), math.floor(r.y + 0.5), r.w, r.h)
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

	-- scroll bar is drawn on top, unclipped
	if self.scrollbar_elem then
		self.scrollbar_elem:draw_rec(ctx)
	end
end

return list_view
