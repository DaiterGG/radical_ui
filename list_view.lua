local class = require("class")
local utils = require("utils")
local apply_display = require("apply_display")
local apply_align = require("apply_align")
local ui_element = require("ui_element")
local box = require("box")

local DEFAULT_WHEEL_SPEED = 80
local DEFAULT_OVERSCROLL = 120
local DEFAULT_SCROLLBAR_WIDTH = 8
local DEFAULT_SCROLLBAR_PADDING = 0
local MIN_THUMB_HEIGHT = 16
local PERCENT = 100
local MAX_DT = 0.05
local SPRING_STIFFNESS = 300
local SPRING_DAMPING = 14
local SPRING_EPSILON = 0.1
local MIDDLE_DEAD_ZONE = 4
local MIDDLE_SCROLL_SPEED = 5
local VIEWPORT_STENCIL_VALUE = 1

local viewport_mask_x = 0
local viewport_mask_y = 0
local viewport_mask_points = nil

local function draw_viewport_mask()
	apply_display.draw_polygon(viewport_mask_x, viewport_mask_y, viewport_mask_points, { 1, 1, 1, 1 })
end

local list_view = class()
list_view.type = "list_view"

function list_view.clamp(v, mn, mx)
	return v < mn and mn or (v > mx and mx or v)
end

-- list_view widget: scrollable vertical list of ui_elements.
-- the owning ui_element's rect is the viewport; children are stacked top to
-- bottom inside it and each child's rect is set with its align function.
-- children rects are slid up by scroll_y (screen space), so draw + collision
-- need no extra transform; the draw scissor clips anything sticking out of
-- the viewport (the rect itself is never clipped).
--
-- two scroll modes (wheel is always on):
--   1) drag the content directly
--   2) drag the scroll bar thumb
-- enabled drag modes come from the list display data:
--   drag_mode = "both" | "only_bar" | "only_drag"  (default "both")
function list_view:new(registry_key, scroll_bar, bar_only, options)
	self.registry_key = registry_key
	self.scrollbar_elem = scroll_bar
	self.drag_mode = bar_only or false
	self.width = options and options.width
	self.padding = options and options.padding
	self.offset = options and options.offset
	self.fixed_height = options and options.fixed_height

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
			child_height = 0,
			viewport_height = 0,
			max_scroll_y = 0,
			wheel_speed = DEFAULT_WHEEL_SPEED,
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
			spring_velocity = 0,
			springing = false,
			overscroll = DEFAULT_OVERSCROLL,
			middle_scrolling = false,
			middle_anchor_y = 0,
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
	if self.children[1] and self.children[1].rect then
		data.child_height = self.children[1].rect.h
	end
	data.viewport_height = r.h
	data.max_scroll_y = math.max(0, data.content_height - r.h)
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
	local r = elem.rect
	if not r or r.h <= 0 then
		return
	end

	local display_data = ctx.display_list[elem.display_key]
	local widget_data = display_data and display_data.list_view
	local sb = widget_data and widget_data.scroll_bar
	if not sb and not self.scrollbar_elem then
		return
	end
	sb = sb or {}

	local width = tonumber(self.width) or tonumber(sb.width) or DEFAULT_SCROLLBAR_WIDTH
	local configured_padding = self.padding
	local style_padding = sb.padding
	local padding_x = DEFAULT_SCROLLBAR_PADDING
	local padding_y = DEFAULT_SCROLLBAR_PADDING
	if type(style_padding) == "number" then
		padding_x = style_padding
		padding_y = style_padding
	elseif type(style_padding) == "table" then
		padding_x = tonumber(style_padding.x) or padding_x
		padding_y = tonumber(style_padding.y) or padding_y
	end
	if type(configured_padding) == "number" then
		padding_x = configured_padding
		padding_y = configured_padding
	elseif type(configured_padding) == "table" then
		padding_x = tonumber(configured_padding.x) or padding_x
		padding_y = tonumber(configured_padding.y) or padding_y
	end
	local offset = tonumber(self.offset)
	if width <= 0 then
		return
	end

	local scale = ctx.state.ui_scale or 1
	local pad_x = padding_x * scale
	local pad_y = padding_y * scale
	local bar_w = width * scale
	local available_w = r.w - pad_x * 2
	if available_w <= 0 then
		return
	end
	bar_w = math.min(bar_w, available_w)

	-- the scroll bar track is the viewport inset by top/bottom padding
	local track_h = r.h - pad_y * 2
	if track_h <= 0 then
		return
	end

	-- thumb height: full track when content fits, shrinking as content grows
	local thumb_h = track_h
	if self.fixed_height ~= nil then
		thumb_h = tonumber(self.fixed_height) * scale
	elseif data.content_height and data.content_height > r.h then
		thumb_h = track_h * (r.h / data.content_height)
	end
	local min_h = math.min(MIN_THUMB_HEIGHT * scale, track_h)
	thumb_h = math.max(thumb_h, min_h)
	thumb_h = math.min(thumb_h, track_h)

	-- bar geometry (screen px), used by the bar drag mode + hit detection
	data.bar_travel = track_h - thumb_h
	data.bar_thumb_h = thumb_h
	data.bar_track_top = r.y + pad_y
	-- Keep the hit column and thumb completely inside the viewport.
	local bar_x = offset and (r.x + r.w * offset / 100 - bar_w / 2) or (r.x + r.w - pad_x - bar_w)
	data.bar_hit = {
		x = bar_x,
		y = r.y + pad_y,
		w = bar_w,
		h = track_h,
	}

	-- thumb position along the track
	local y_off = pad_y
	if data.max_scroll_y and data.max_scroll_y > 0 then
		local settled_scroll = list_view.clamp(data.scroll_y, 0, data.max_scroll_y)
		y_off = y_off + (settled_scroll / data.max_scroll_y) * data.bar_travel
	end

	-- absolute align values (parent_pivot/pivot are 0..100 percentages).
	local parent_pivot = { x = offset or PERCENT, y = 0 }
	local pivot = {
		x = offset and 50 or PERCENT,
		y = -PERCENT * y_off / thumb_h,
	}
	local size = apply_align.Size({
		px_hor = width,
		pc_vert = (thumb_h / r.h) * PERCENT,
	})

	if not data.scrollbar_align then
		data.scrollbar_align = apply_align.Align():absolute({
			pivot = pivot,
			parent_pivot = parent_pivot,
			size = size,
		})
	else
		data.scrollbar_align.pivot.x = pivot.x
		data.scrollbar_align.pivot.y = pivot.y
		data.scrollbar_align.parent_pivot.x = parent_pivot.x
		data.scrollbar_align.parent_pivot.y = parent_pivot.y
		data.scrollbar_align.size = size
	end
	self.scrollbar_elem.align = data.scrollbar_align
	self.scrollbar_elem.previous_parent_rect = nil

	-- generate the bar rect (and its children) from the scroll view rect
	self.scrollbar_elem:align_rec({ x = r.x, y = r.y, w = r.w, h = r.h }, ctx)
end

function list_view:start_spring(data)
	if data.scroll_y < 0 or data.scroll_y > data.max_scroll_y then
		data.springing = true
	end
end

function list_view:spring_to_limit(data, dt)
	if not data.springing then
		return
	end

	local target = list_view.clamp(data.scroll_y, 0, data.max_scroll_y)
	local displacement = target - data.scroll_y
	data.spring_velocity = data.spring_velocity + displacement * SPRING_STIFFNESS * dt
	data.spring_velocity = data.spring_velocity * math.exp(-SPRING_DAMPING * dt)
	local next_scroll = data.scroll_y + data.spring_velocity * dt

	-- Stop at the limit instead of allowing the spring to overshoot it.
	if (data.scroll_y < target and next_scroll >= target) or (data.scroll_y > target and next_scroll <= target) then
		data.scroll_y = target
		data.spring_velocity = 0
		data.springing = false
		return
	end
	data.scroll_y = next_scroll

	if math.abs(target - data.scroll_y) < SPRING_EPSILON and math.abs(data.spring_velocity) < SPRING_EPSILON then
		data.scroll_y = target
		data.spring_velocity = 0
		data.springing = false
	end
end

function list_view:set_drag_scroll(data, value)
	data.scroll_y = value
end

function list_view:set_bar_scroll(data, value)
	data.scroll_y = list_view.clamp(value, 0, data.max_scroll_y)
	data.springing = false
	data.spring_velocity = 0
end

function list_view:update_scroll(elem, ctx)
	local data = self:get_data(ctx)
	local r = elem.rect

	data.max_scroll_y = math.max(0, data.content_height - r.h)
	local display_data = ctx.display_list[elem.display_key]
	local widget_data = display_data and display_data.list_view
	local scroll_speed = tonumber(widget_data and widget_data.scroll_speed) or 1

	local input = ctx.input_state
	local mx = input.pos.x
	local my = input.pos.y

	local in_rect = mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h

	local old_scroll = data.scroll_y
	local dt = math.min(ctx.state.last_delta or 0, MAX_DT)
	local user_scrolled = false

	local middle_held = input.middle == "held" or input.middle == "pressed"
	if data.middle_scrolling then
		if middle_held then
			-- The anchor stays fixed: a larger cursor distance produces a
			-- faster continuous scroll, even when the cursor stops moving.
			local distance = my - data.middle_anchor_y
			if math.abs(distance) > MIDDLE_DEAD_ZONE then
				local direction = distance < 0 and -1 or 1
				local speed = (math.abs(distance) - MIDDLE_DEAD_ZONE) * MIDDLE_SCROLL_SPEED
				self:set_drag_scroll(data, data.scroll_y + direction * speed * dt)
				user_scrolled = true
			end
		else
			data.middle_scrolling = false
			input.interacting_with = nil
			if ctx.cursor then
				ctx.cursor:set_state("idle")
			end
			self:start_spring(data)
		end
	elseif in_rect and input.middle == "pressed" then
		data.middle_scrolling = true
		data.middle_anchor_y = my
		data.springing = false
		data.spring_velocity = 0
		if ctx.cursor then
			ctx.cursor:set_state("scroll")
		end
		input.interacting_with = elem
	end

	-- which drag interactions are enabled (wheel is always on):
	--   drag_mode: "both" | "only_bar" | "only_drag"
	local allow_bar = self.scrollbar_elem and true
	local allow_drag = not self.drag_mode

	-- wheel scroll (wheel up -> toward the top); works in both drag modes and
	-- keeps working while a drag is active even if the pointer left the viewport
	local wheel_active = in_rect
	if wheel_active and input.scroll_y and input.scroll_y ~= 0 then
		self:set_drag_scroll(data, data.scroll_y - input.scroll_y * data.wheel_speed * scroll_speed)
		input.scroll_y = 0
		self:start_spring(data)
		user_scrolled = true
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
				self:set_bar_scroll(
					data,
					data.bar_drag_scroll_start + (my - data.bar_drag_start_y) * (data.max_scroll_y / data.bar_travel)
				)
			end
		else
			data.bar_dragging = false -- button released -> stop dragging
			input.interacting_with = nil
			self:start_spring(data)
		end
	elseif data.max_scroll_y > 0 and over_bar and input.left == "pressed" then
		data.bar_dragging = true
		input.interacting_with = elem

		-- where on the thumb the pointer grabbed it (0..thumb_h)
		local settled_scroll = list_view.clamp(data.scroll_y, 0, data.max_scroll_y)
		local thumb_top = data.bar_track_top + (settled_scroll / data.max_scroll_y) * data.bar_travel
		local grab = list_view.clamp(my - thumb_top, 0, data.bar_thumb_h)

		-- place the thumb so the grabbed point stays under the pointer
		if data.bar_travel > 0 then
			self:set_bar_scroll(data, ((my - grab - data.bar_track_top) / data.bar_travel) * data.max_scroll_y)
		end
		data.bar_drag_start_y = my
		data.bar_drag_scroll_start = data.scroll_y
	end

	-- scroll mode 1: drag the content (not while the bar is grabbed)
	if not data.bar_dragging then
		if data.is_dragging then
			if held then
				self:set_drag_scroll(data, data.drag_scroll_start_y - (my - data.drag_start_y))
			else
				data.is_dragging = false -- button released -> stop dragging
				input.interacting_with = nil
				self:start_spring(data)
			end
		elseif not data.middle_scrolling and allow_drag and in_rect and not over_bar and input.left == "pressed" then
			data.is_dragging = true
			data.drag_start_y = my
			data.drag_scroll_start_y = data.scroll_y
			input.interacting_with = elem
		end
	end

	if not data.is_dragging and not data.bar_dragging and not data.middle_scrolling and not user_scrolled then
		self:spring_to_limit(data, dt)
	end

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
		or data.middle_scrolling
		or data.springing
		or (hit and (input.left == "pressed" or input.middle == "pressed" or input.scroll_y ~= 0))
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

function list_view:draw(elem, ctx, widget_display_data, display_data)
	local widget_data = widget_display_data
	local r = elem.rect

	-- background
	apply_display.draw_background(
		widget_data,
		ctx,
		r,
		elem.polyline,
		elem
	)

	if #self.children > 0 then
		if elem.polyline then
			self:draw_polyline_content(elem, ctx)
		else
			self:draw_rectangular_content(ctx, r)
		end
	end

	-- scroll bar is drawn on top, unclipped
	if self.scrollbar_elem then
		self.scrollbar_elem:draw_rec(ctx)
	end
end

function list_view:draw_rectangular_content(ctx, r)
		-- Use scissor for the rectangular viewport. Descendant backgrounds may
		-- use stencil operations of their own, which must not replace the list
		-- viewport's clipping state.
	love.graphics.push("all")
	love.graphics.setScissor(r.x, r.y, r.w, r.h)

	for _, child in ipairs(self.children) do
		if not child.rect or child.rect.y > ctx.state.res.h then
			break
		end
		if child.rect.y + child.rect.h > 0 then
			child:draw_rec(ctx)
		end
	end

	love.graphics.pop()
end

function list_view:draw_polyline_content(elem, ctx)
	love.graphics.push("all")
	viewport_mask_x = elem.rect.x
	viewport_mask_y = elem.rect.y
	viewport_mask_points = apply_display.scale_points(elem.polyline, ctx.state.ui_scale or 1)
	love.graphics.stencil(draw_viewport_mask, "replace", VIEWPORT_STENCIL_VALUE)
	love.graphics.setStencilTest("greater", 0)

	for _, child in ipairs(self.children) do
		if not child.rect or child.rect.y > ctx.state.res.h then
			break
		end
		if child.rect.y + child.rect.h > 0 then
			child:draw_rec(ctx)
		end
	end

	love.graphics.setStencilTest()
	love.graphics.pop()
end

return list_view
