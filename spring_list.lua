local class = require("class")
local apply_display = require("apply_display")

local MAX_DT = 0.05
local SNAP_BASE_SPEED = 200
local SNAP_DISTANCE_SPEED = 6
local OVERSCROLL_BASE_SPEED = 200
local OVERSCROLL_DISTANCE_SPEED = 12
local SNAP_POSITION_EPSILON = 0.1
local MIDDLE_DEAD_ZONE = 4
local MIDDLE_SCROLL_SPEED = 10
local DRAG_DEAD_ZONE = 10
local HORIZONTAL_SPRING_STIFFNESS = 120
local HORIZONTAL_SPRING_DAMPING = 22
local HORIZONTAL_ACTIVE_VELOCITY_EPSILON = 0.1
local HORIZONTAL_RELEASE_FORCE = 60
local HORIZONTAL_START_OUTSIDE_RATIO = 0.25
local HORIZONTAL_DRAG_RESPONSE = 24
local HORIZONTAL_MAX_ROTATION = math.rad(4)
local HORIZONTAL_MAX_VERTICAL_SPREAD_RATIO = 0.08
local HORIZONTAL_SCROLL_LOCK_RATIO = 1
local HORIZONTAL_FULL_STRETCH_EPSILON = 0.999
local VERTICAL_CURSOR_FOLLOW_START_RATIO = 0.5
local VERTICAL_CURSOR_FOLLOW_MAX_RATIO = 0.1
local VIRTUAL_ROW_COUNT = 9
local SHORT_LIST_ITEM_COUNT = 7
local DEFAULT_ITEM_GAP = 10

local INTERACTION_IDLE = "idle"
local INTERACTION_DRAG_PENDING = "drag_pending"
local INTERACTION_DRAGGING = "dragging"
local INTERACTION_MIDDLE_SCROLLING = "middle_scrolling"
local INTERACTION_RIGHT_SCROLLING = "right_scrolling"

local function clamp(value, minimum, maximum)
	return value < minimum and minimum or (value > maximum and maximum or value)
end

local function horizontal_influence(rect, item_y, item_h)
	local center = rect.y + rect.h / 2
	local edge_distance = math.max(1, rect.h / 2 - item_h / 2)
	local distance = math.abs(item_y + item_h / 2 - center)
	local linear = clamp(1 - distance / edge_distance, 0, 1)
	return linear * linear * (3 - 2 * linear)
end

local function is_short_list(data)
	return data.item_count > 0 and data.item_count < SHORT_LIST_ITEM_COUNT
end

local function centered_scroll_offset(data, rect)
	return (data.content_height - rect.h) / 2
end

local function item_geometry(data)
	local item_height = data.item_height
	local item_pitch = data.item_pitch
	local item_gap = data.item_gap or DEFAULT_ITEM_GAP
	if not item_height or item_height <= 0 then
		item_height = item_pitch and item_pitch > item_gap and item_pitch - item_gap or 0
	end
	if not item_pitch or item_pitch <= 0 then
		item_pitch = item_height + item_gap
	end
	return item_height, item_pitch, item_gap
end

local function item_top(data, index)
	local _, item_pitch, item_gap = item_geometry(data)
	return item_gap + (index - 1) * item_pitch
end

local function effective_scroll(data, rect)
	if is_short_list(data) then
		return data.scroll_y - centered_scroll_offset(data, rect)
	end
	return data.scroll_y
end

local function center_index(data, rect)
	local item_height, item_pitch, item_gap = item_geometry(data)
	return math.floor(
		(effective_scroll(data, rect) + rect.h / 2 - item_height / 2 - item_gap)
			/ math.max(1, item_pitch)
	) + 1
end

local function set_scroll_to_current(data, rect)
	if data.item_count <= 0 then
		return
	end
	local current_index = center_index(data, rect)
	data.scroll_to = clamp(current_index, 1, data.item_count)
end

local function update_scroll_to(data, rect, dt)
	if data.item_count <= 0 then
		return
	end

	local item_height = select(1, item_geometry(data))
	local target_scroll = item_top(data, data.scroll_to) - (rect.h - item_height) / 2
	if is_short_list(data) then
		target_scroll = target_scroll + centered_scroll_offset(data, rect)
	else
		target_scroll = clamp(target_scroll, 0, data.max_scroll_y)
	end
	local displacement = target_scroll - data.scroll_y
	if math.abs(displacement) < SNAP_POSITION_EPSILON then
		data.scroll_y = target_scroll
		data.scroll_to = nil
		return
	end

	local overscroll_distance = data.scroll_y < 0
		and -data.scroll_y
		or math.max(0, data.scroll_y - data.max_scroll_y)
	local speed = overscroll_distance > 0
		and OVERSCROLL_BASE_SPEED + overscroll_distance * OVERSCROLL_DISTANCE_SPEED
		or SNAP_BASE_SPEED + math.abs(displacement) * SNAP_DISTANCE_SPEED
	data.scroll_y = data.scroll_y + (displacement > 0 and 1 or -1) * math.min(math.abs(displacement), speed * dt)
end

local function update_horizontal_motion(data, dt)
	if data.interaction_state == INTERACTION_DRAG_PENDING or data.interaction_state == INTERACTION_DRAGGING then
		return
	end
	data.horizontal_acceleration = -data.horizontal_offset * HORIZONTAL_SPRING_STIFFNESS
		- data.horizontal_velocity * HORIZONTAL_SPRING_DAMPING
	data.horizontal_velocity = data.horizontal_velocity + data.horizontal_acceleration * dt
	data.horizontal_offset = data.horizontal_offset + data.horizontal_velocity * dt
	if
		math.abs(data.horizontal_offset) < HORIZONTAL_ACTIVE_VELOCITY_EPSILON
		and math.abs(data.horizontal_velocity) < HORIZONTAL_ACTIVE_VELOCITY_EPSILON
	then
		data.horizontal_offset = 0
		data.horizontal_velocity = 0
		data.horizontal_acceleration = 0
	end
end

local function horizontal_drag_target(rect, mouse_x)
	local start_distance = rect.w * HORIZONTAL_START_OUTSIDE_RATIO
	local relative_x = mouse_x - rect.x

	if relative_x < -start_distance then
		local progress = clamp((-relative_x - start_distance) / math.max(1, rect.w), 0, 1)
		return -rect.w * progress
	elseif relative_x > rect.w + start_distance then
		local progress = clamp((relative_x - rect.w - start_distance) / math.max(1, rect.w), 0, 1)
		return rect.w * progress
	else
		return 0
	end
end

local function vertical_scroll_factor(rect, horizontal_offset)
	local lock_distance = math.max(1, rect.w * HORIZONTAL_SCROLL_LOCK_RATIO)
	local progress = clamp(math.abs(horizontal_offset) / lock_distance, 0, 1)
	local remaining = 1 - progress
	return remaining * remaining
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
			interaction_state = INTERACTION_IDLE,
			drag_start_x = 0,
			drag_start_y = 0,
			drag_pointer_x = 0,
			drag_pointer_y = 0,
			drag_cursor_x = 0,
			drag_cursor_y = 0,
			horizontal_offset = 0,
			horizontal_velocity = 0,
			horizontal_acceleration = 0,
			middle_anchor_y = 0,
			item_count = 0,
			item_height = 0,
			item_pitch = 0,
			item_gap = DEFAULT_ITEM_GAP,
			range_start = 1,
			range_end = 0,
		}
		ctx.beatmaps.spring_list_data = data
	end
	-- Keep state valid if the view is rebuilt after loading an older version.
	data.scroll_y = data.scroll_y or 0
	data.content_height = data.content_height or 0
	data.max_scroll_y = data.max_scroll_y or 0
	if not data.interaction_state then
		if data.middle_scrolling then
			data.interaction_state = INTERACTION_MIDDLE_SCROLLING
		elseif data.right_scrolling then
			data.interaction_state = INTERACTION_RIGHT_SCROLLING
		elseif data.is_dragging then
			data.interaction_state = data.drag_active and INTERACTION_DRAGGING or INTERACTION_DRAG_PENDING
		else
			data.interaction_state = INTERACTION_IDLE
		end
	end
	data.is_dragging = nil
	data.drag_active = nil
	data.middle_scrolling = nil
	data.right_scrolling = nil
	data.snapping = nil
	data.drag_start_x = data.drag_start_x or 0
  data.drag_start_y = data.drag_start_y or 0
	data.drag_pointer_x = data.drag_pointer_x or 0
	data.drag_pointer_y = data.drag_pointer_y or 0
	data.drag_cursor_y = data.drag_cursor_y or 0
	data.drag_cursor_x = data.drag_cursor_x or 0


	data.horizontal_offset = data.horizontal_offset or 0
	data.horizontal_velocity = data.horizontal_velocity or 0
	data.horizontal_acceleration = data.horizontal_acceleration or 0
	data.item_count = data.item_count or 0
	data.item_height = data.item_height or 0
	data.item_pitch = data.item_pitch or 0
	data.item_gap = data.item_gap or DEFAULT_ITEM_GAP
	data.range_start = data.range_start or 1
	data.range_end = data.range_end or 0
	return data
end

function spring_list:add_child(child)
	table.insert(self.children, child)
end

function spring_list:realign(ctx, elem)
	local data = self:get_data(ctx)
	local rect = elem.rect
	local y = rect.y
	local content_height = 0

	for _, child in ipairs(self.children) do
		child:align_rec({ x = rect.x, y = y, w = rect.w, h = rect.h }, ctx)
		if child.rect then
			y = y + child.rect.h
			content_height = content_height + child.rect.h
		end
	end

	data.content_height = content_height
	local first_row_index = 2
	local first_row = self.children[first_row_index]
	if first_row and first_row.rect then
		data.item_pitch = first_row.rect.h
		data.item_height = math.max(0, data.item_pitch - (data.item_gap or DEFAULT_ITEM_GAP))
	end
	data.max_scroll_y = math.max(0, data.content_height - rect.h)
	local start_y = rect.y - data.scroll_y
	if is_short_list(data) then
		start_y = rect.y + (rect.h - data.content_height) / 2 - data.scroll_y
	end

	y = start_y
	local cursor_follow_progress = clamp(
		(math.abs(data.horizontal_offset) / math.max(1, rect.w) - VERTICAL_CURSOR_FOLLOW_START_RATIO)
			/ (1 - VERTICAL_CURSOR_FOLLOW_START_RATIO),
		0,
		1
	)
	local cursor_y = (
		data.interaction_state == INTERACTION_DRAG_PENDING or data.interaction_state == INTERACTION_DRAGGING
	)
			and data.drag_cursor_y
		or ctx.input_state.pos.y
	local cursor_offset = (cursor_y - (rect.y + rect.h / 2)) * VERTICAL_CURSOR_FOLLOW_MAX_RATIO * cursor_follow_progress
	for _, child in ipairs(self.children) do
		local child_height = child.rect and child.rect.h or 0
		local influence = horizontal_influence(rect, y, child_height)
		local center_y = rect.y + rect.h / 2
		local item_center_y = y + child_height / 2
		local away_from_center = item_center_y < center_y and -1 or 1
		local vertical_spread = rect.h
			* HORIZONTAL_MAX_VERTICAL_SPREAD_RATIO
			* influence
			* clamp(math.abs(item_center_y - center_y) / math.max(1, rect.h / 2), 0, 1)
			* clamp(math.abs(data.horizontal_offset) / math.max(1, rect.w), 0, 1)
		local visual_y = y + away_from_center * vertical_spread
		visual_y = visual_y + cursor_offset * influence
		local x = rect.x + data.horizontal_offset * influence
		child:align_rec({ x = x, y = visual_y, w = rect.w, h = rect.h }, ctx)
		if child.rect then
			y = y + child.rect.h
		end
	end
end

function spring_list:update_scroll(elem, ctx)
	local data = self:get_data(ctx)
	local rect = elem.rect
	local input = ctx.input_state
	local mouse_x = input.pos.x
	local mouse_y = input.pos.y
	local old_scroll = data.scroll_y
	local old_horizontal_offset = data.horizontal_offset
	local old_drag_cursor_x = data.drag_cursor_x
	local old_drag_cursor_y = data.drag_cursor_y
	local dt = math.min(ctx.dt or 0, MAX_DT)
	local user_scrolled = false

	if data.interaction_state == INTERACTION_DRAG_PENDING or data.interaction_state == INTERACTION_DRAGGING then
		mouse_x = data.drag_pointer_x + input.delta.x
		mouse_y = data.drag_pointer_y + input.delta.y
	end

	local inside = mouse_x >= rect.x and mouse_x < rect.x + rect.w and mouse_y >= rect.y and mouse_y < rect.y + rect.h

	data.max_scroll_y = math.max(0, data.content_height - rect.h)
	local middle_held = input.middle == "held" or input.middle == "pressed"
	if data.interaction_state == INTERACTION_MIDDLE_SCROLLING then
		if middle_held then
			local distance = mouse_y - data.middle_anchor_y
			if math.abs(distance) > MIDDLE_DEAD_ZONE then
				local direction = distance < 0 and -1 or 1
				local speed = (math.abs(distance) - MIDDLE_DEAD_ZONE) * MIDDLE_SCROLL_SPEED
				data.scroll_y = data.scroll_y
					+ direction * speed * dt * vertical_scroll_factor(rect, data.horizontal_offset)
			end
		else
			data.interaction_state = INTERACTION_IDLE
			set_scroll_to_current(data, rect)
			input.interacting_with = nil
			if ctx.cursor then
				ctx.cursor:set_state("idle")
			end
		end
	elseif inside and input.middle == "pressed" then
		data.interaction_state = INTERACTION_MIDDLE_SCROLLING
		data.middle_anchor_y = mouse_y
		data.scroll_to = nil
		if ctx.cursor then
			ctx.cursor:set_state("scroll")
		end
	end

	local right_held = input.right == "held" or input.right == "pressed"
	if data.interaction_state == INTERACTION_RIGHT_SCROLLING then
		if right_held then
			local progress = clamp((mouse_y - rect.y) / rect.h, 0, 1)
			data.scroll_y = progress * data.max_scroll_y
		else
			data.interaction_state = INTERACTION_IDLE
			set_scroll_to_current(data, rect)
			input.interacting_with = nil
			if ctx.cursor then
				ctx.cursor:set_state("idle")
			end
		end
	elseif inside and input.right == "pressed" then
		data.interaction_state = INTERACTION_RIGHT_SCROLLING
		data.scroll_to = nil
		local progress = clamp((mouse_y - rect.y) / rect.h, 0, 1)
		data.scroll_y = progress * data.max_scroll_y
		if ctx.cursor then
			ctx.cursor:set_state("idle")
		end
	end

	if inside and input.scroll_y and input.scroll_y ~= 0 then
		local wheel_delta = input.scroll_y > 0 and -1 or 1
		local wheel_distance = math.abs(input.scroll_y)
		if data.item_count > 0 and math.abs(data.horizontal_offset) < rect.w * HORIZONTAL_FULL_STRETCH_EPSILON then
			local current_index = data.scroll_to
				or center_index(data, rect)
			data.scroll_to = clamp(current_index + wheel_delta * wheel_distance, 1, data.item_count)
		end
		input.scroll_y = 0
		user_scrolled = true
	end

	local held = input.left == "held" or input.left == "pressed"
	if data.interaction_state == INTERACTION_DRAG_PENDING or data.interaction_state == INTERACTION_DRAGGING then
		if held then
			data.drag_pointer_x = mouse_x
			data.drag_pointer_y = mouse_y
			if data.interaction_state == INTERACTION_DRAG_PENDING then
				local drag_delta_x = mouse_x - data.drag_start_x
				local drag_delta_y = mouse_y - data.drag_start_y
				local drag_distance = math.sqrt(drag_delta_x * drag_delta_x + drag_delta_y * drag_delta_y)
				if drag_distance > DRAG_DEAD_ZONE then
					local active_distance = drag_distance - DRAG_DEAD_ZONE
					local scale = active_distance / drag_distance
					mouse_x = data.drag_start_x + drag_delta_x * scale
					mouse_y = data.drag_start_y + drag_delta_y * scale
					data.drag_cursor_x = data.drag_start_x
					data.drag_cursor_y = data.drag_start_y
					data.interaction_state = INTERACTION_DRAGGING
					data.scroll_to = nil
					input.interacting_with = elem.hash_num
				else
					input.interacting_with = nil
					data.drag_cursor_x = data.drag_start_x
					data.drag_cursor_y = data.drag_start_y
				end
			end

			if data.interaction_state == INTERACTION_DRAGGING then
				local previous_drag_cursor_y = data.drag_cursor_y
				data.drag_cursor_x = mouse_x
				data.drag_cursor_y = mouse_y
				local drag_delta_y = data.drag_cursor_y - previous_drag_cursor_y
				local next_horizontal_offset = horizontal_drag_target(rect, data.drag_cursor_x)
				local scroll_factor = vertical_scroll_factor(rect, next_horizontal_offset)
				local next_scroll = data.scroll_y - drag_delta_y * scroll_factor
				if dt > 0 then
					local measured_horizontal_velocity = (next_horizontal_offset - data.horizontal_offset) / dt
					data.horizontal_acceleration = (measured_horizontal_velocity - data.horizontal_velocity)
						* HORIZONTAL_DRAG_RESPONSE
					data.horizontal_velocity = data.horizontal_velocity + data.horizontal_acceleration * dt
				end
				data.scroll_y = next_scroll
				data.horizontal_offset = next_horizontal_offset
			end
		else
			local was_drag_active = data.interaction_state == INTERACTION_DRAGGING
			data.interaction_state = INTERACTION_IDLE
			data.horizontal_velocity = data.horizontal_velocity - data.horizontal_offset * HORIZONTAL_RELEASE_FORCE
			if was_drag_active then
				set_scroll_to_current(data, rect)
			end
		end
		if input.left == "idle" then
			input.interacting_with = nil
    end
	elseif
		data.interaction_state == INTERACTION_IDLE
		and inside
		and input.left == "pressed"
	then
		data.interaction_state = INTERACTION_DRAG_PENDING
		data.drag_start_x = mouse_x
		data.drag_start_y = mouse_y
		data.drag_pointer_x = mouse_x
		data.drag_pointer_y = mouse_y
		data.drag_cursor_x = mouse_x
		data.drag_cursor_y = mouse_y
	end

	if (data.interaction_state == INTERACTION_IDLE or data.interaction_state == INTERACTION_DRAG_PENDING) and not user_scrolled and data.scroll_to ~= nil then
		update_scroll_to(data, rect, dt)
	end
	update_horizontal_motion(data, dt)
	return data.scroll_y ~= old_scroll
		or data.horizontal_offset ~= old_horizontal_offset
		or data.drag_cursor_x ~= old_drag_cursor_x
		or data.drag_cursor_y ~= old_drag_cursor_y
end

function spring_list:update_virtual_range(elem, ctx)
	local data = self:get_data(ctx)
	if data.item_count <= 0 then
		return
	end

	local first_row_index = 2
	local first_row = self.children[first_row_index]
	local item_height = first_row and first_row.rect and first_row.rect.h or 0
	if item_height <= 0 then
		return
	end

	local range_count = math.min(VIRTUAL_ROW_COUNT, data.item_count)
	local current_index = center_index(data, elem.rect)
	local range_start = math.max(1, current_index - math.floor(range_count / 2))
	range_start = math.min(range_start, data.item_count - range_count + 1)
	local range_end = range_start + range_count - 1

	if range_start ~= data.range_start or range_end ~= data.range_end then
		data.range_start = range_start
		data.range_end = range_end
		ctx.ui.need_to_rebuild = true
	end
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
	local active =
		-- input.interacting_with == elem.hash_num or
		data.interaction_state ~= INTERACTION_IDLE or data.scroll_to ~= nil or math.abs(data.horizontal_velocity) > HORIZONTAL_ACTIVE_VELOCITY_EPSILON or math.abs(
			data.horizontal_offset
		) > HORIZONTAL_ACTIVE_VELOCITY_EPSILON or (hit and (input.left == "pressed" or input.right == "pressed" or input.middle == "pressed" or input.scroll_y ~= 0))
	if active then
		local changed = self:update_scroll(elem, ctx)
		if changed or data.scroll_to ~= nil then
			self:realign(ctx, elem)
		end
	end
	self:update_virtual_range(elem, ctx)
	for _, child in ipairs(self.children) do
		local child_rect = child.rect
		if
			child_rect
			and child_rect.y + child_rect.h >= 0
			and child_rect.y <= ctx.res.h
			and child_rect.x + child_rect.w >= 0
			and child_rect.x <= ctx.res.w
		then
			child:pointer_collision_rec(ctx, hit)
		end
	end
end

function spring_list:draw(elem, ctx, widget_display_data, display_data)
	local widget_data = widget_display_data
	local data = self:get_data(ctx)
	local rect = elem.rect
	apply_display.draw_background(
		widget_data,
		ctx,
		rect,
		elem.polyline,
		elem
	)
	if #self.children == 0 then
		return
	end

	for index, child in ipairs(self.children) do
		local child_rect = child.rect
		if
			child_rect
			and child_rect.y + child_rect.h >= 0
			and child_rect.y <= ctx.res.h
			and child_rect.x + child_rect.w >= 0
			and child_rect.x <= ctx.res.w
		then
			local influence = horizontal_influence(rect, child_rect.y, child_rect.h)
			local direction = index % 2 == 1 and 1 or -1
			local stretch = clamp(math.abs(data.horizontal_offset) / math.max(1, rect.w), 0, 1)
			local rotation = direction * HORIZONTAL_MAX_ROTATION * influence * stretch
			local center_x = child_rect.x + child_rect.w / 2
			local center_y = child_rect.y + child_rect.h / 2

			love.graphics.push()
			love.graphics.translate(center_x, center_y)
			love.graphics.rotate(rotation)
			love.graphics.translate(-center_x, -center_y)
			child:draw_rec(ctx)
			love.graphics.pop()
		end
	end
end

return spring_list
