local class = require("class")
local apply_display = require("apply_display")

local ROW_COUNT = 7
local MAX_DT = 0.05
local AIR_FRICTION = 24
local SNAP_VELOCITY_THRESHOLD = 24
local SNAP_STIFFNESS = 165
local SNAP_DAMPING = 25
local OVERSCROLL_STIFFNESS = 240
local OVERSCROLL_DAMPING = 32
local SNAP_POSITION_EPSILON = 0.1
local SNAP_VELOCITY_EPSILON = 0.1
local ACTIVE_VELOCITY_EPSILON = 0.1
local SNAP_ROUNDING_OFFSET = 0.5
local MIDDLE_DEAD_ZONE = 4
local MIDDLE_SCROLL_SPEED = 5
local MIDDLE_SCROLL_ACCELERATION = 20
local DRAG_ACCELERATION = 24
local HORIZONTAL_AIR_FRICTION = 18
local HORIZONTAL_SPRING_STIFFNESS = 120
local HORIZONTAL_SPRING_DAMPING = 22
local HORIZONTAL_ACTIVE_VELOCITY_EPSILON = 0.1
local HORIZONTAL_RELEASE_FORCE = 60
local HORIZONTAL_START_OUTSIDE_RATIO = 0.25
local HORIZONTAL_DRAG_RESPONSE = 24
local HORIZONTAL_MAX_ROTATION = math.rad(4)
local HORIZONTAL_MAX_VERTICAL_SPREAD_RATIO = 0.08
local HORIZONTAL_SCROLL_LOCK_RATIO = 1
local VERTICAL_LOCK_DAMPING = 0.0001
local VERTICAL_LOCK_EPSILON = 0.1
local HORIZONTAL_FULL_STRETCH_EPSILON = 0.999
local VERTICAL_CURSOR_FOLLOW_START_RATIO = 0.5
local VERTICAL_CURSOR_FOLLOW_MAX_RATIO = 0.1

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

local function snap_position(data, elem_h, value)
	if elem_h <= 0 then
		return clamp(value, 0, data.max_scroll_y)
	end
	local snapped = math.floor(value / elem_h + SNAP_ROUNDING_OFFSET) * elem_h
	return clamp(snapped, 0, data.max_scroll_y)
end

local function start_snap(data, elem_h)
	data.snap_target = snap_position(data, elem_h, data.scroll_y)
	data.snapping = true
end

local function start_directional_snap(data, elem_h, direction)
	if elem_h <= 0 then
		start_snap(data, elem_h)
		return
	end

	local base_position = data.snapping and data.snap_target or data.scroll_y
	local current_index = math.floor(base_position / elem_h + SNAP_ROUNDING_OFFSET)
	local target_index = current_index + (direction > 0 and 1 or -1)
	data.snap_target = clamp(target_index * elem_h, 0, data.max_scroll_y)
	data.snapping = true
end

local function start_wheel_snap(data, elem_h, direction)
	if elem_h <= 0 then
		start_snap(data, elem_h)
		return
	end

	local base_position = data.snapping and data.snap_target or data.scroll_y
	local current_index = math.floor(base_position / elem_h + SNAP_ROUNDING_OFFSET)
	local target = (current_index + (direction > 0 and 1 or -1)) * elem_h

	data.velocity = 0
	if target < 0 or target > data.max_scroll_y then
		data.scroll_y = target
		data.snap_target = clamp(target, 0, data.max_scroll_y)
	else
		data.snap_target = target
	end
	data.snapping = true
end

local function stop_motion(data)
	data.velocity = 0
	data.acceleration = 0
	data.snapping = false
end

local function update_motion(data, dt, elem_h)
	local out_of_bounds = data.scroll_y < 0 or data.scroll_y > data.max_scroll_y
	if out_of_bounds then
		data.snap_target = clamp(data.scroll_y, 0, data.max_scroll_y)
		data.snapping = true
	end

	if data.snapping then
		local displacement = data.snap_target - data.scroll_y
		local stiffness = out_of_bounds and OVERSCROLL_STIFFNESS or SNAP_STIFFNESS
		local damping = out_of_bounds and OVERSCROLL_DAMPING or SNAP_DAMPING
		data.acceleration = displacement * stiffness - data.velocity * damping
		data.velocity = data.velocity + data.acceleration * dt
		data.scroll_y = data.scroll_y + data.velocity * dt
		if math.abs(displacement) < SNAP_POSITION_EPSILON and math.abs(data.velocity) < SNAP_VELOCITY_EPSILON then
			data.scroll_y = data.snap_target
			stop_motion(data)
		end
		return
	end

	-- High air friction makes a released drag lose speed quickly.
	data.acceleration = -data.velocity * AIR_FRICTION
	data.velocity = data.velocity + data.acceleration * dt
	data.scroll_y = data.scroll_y + data.velocity * dt

	if math.abs(data.velocity) < SNAP_VELOCITY_THRESHOLD then
		start_snap(data, elem_h)
	end
end

local function update_horizontal_motion(data, dt)
	if data.is_dragging then
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
			is_dragging = false,
			drag_start_y = 0,
			drag_scroll_start_y = 0,
			drag_direction = 0,
			drag_cursor_x = 0,
			drag_cursor_y = 0,
			right_scrolling = false,
			velocity = 0,
			acceleration = 0,
			horizontal_offset = 0,
			horizontal_velocity = 0,
			horizontal_acceleration = 0,
			snapping = false,
			snap_target = 0,
			middle_scrolling = false,
			middle_anchor_y = 0,
		}
		ctx.beatmaps.spring_list_data = data
	end
	-- Keep state valid if the view is rebuilt after loading an older version.
	data.velocity = data.velocity or 0
	data.acceleration = data.acceleration or 0
	data.snapping = data.snapping or false
	data.snap_target = data.snap_target or 0
	data.right_scrolling = data.right_scrolling or false
	data.drag_cursor_y = data.drag_cursor_y or 0
	data.drag_cursor_x = data.drag_cursor_x or 0

	data.horizontal_offset = data.horizontal_offset or 0
	data.horizontal_velocity = data.horizontal_velocity or 0
	data.horizontal_acceleration = data.horizontal_acceleration or 0
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
	data.max_scroll_y = math.max(0, data.content_height - rect.h)

	local start_y = rect.y - data.scroll_y
	if data.content_height < rect.h then
		start_y = rect.y + (rect.h - data.content_height) / 2
	end

	y = start_y
	local cursor_follow_progress = clamp(
		(math.abs(data.horizontal_offset) / math.max(1, rect.w) - VERTICAL_CURSOR_FOLLOW_START_RATIO)
			/ (1 - VERTICAL_CURSOR_FOLLOW_START_RATIO),
		0,
		1
	)
	local cursor_y = data.is_dragging and data.drag_cursor_y or ctx.input_state.pos.y
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

	if data.is_dragging then
		mouse_x = data.drag_cursor_x + input.delta.x
		mouse_y = data.drag_cursor_y + input.delta.y
	end

	local inside = mouse_x >= rect.x and mouse_x < rect.x + rect.w and mouse_y >= rect.y and mouse_y < rect.y + rect.h

	data.max_scroll_y = math.max(0, data.content_height - rect.h)
	local elem_h = rect.h / ROW_COUNT

	local middle_held = input.middle == "held" or input.middle == "pressed"
	if data.middle_scrolling then
		if middle_held then
			local distance = mouse_y - data.middle_anchor_y
			if math.abs(distance) > MIDDLE_DEAD_ZONE then
				local direction = distance < 0 and -1 or 1
				local target_velocity = direction * (math.abs(distance) - MIDDLE_DEAD_ZONE) * MIDDLE_SCROLL_SPEED
				data.acceleration = (target_velocity - data.velocity) * MIDDLE_SCROLL_ACCELERATION
				data.velocity = data.velocity + data.acceleration * dt
				data.scroll_y = data.scroll_y
					+ data.velocity * dt * vertical_scroll_factor(rect, data.horizontal_offset)
			end
		else
			data.middle_scrolling = false
			input.interacting_with = nil
			if ctx.cursor then
				ctx.cursor:set_state("idle")
			end
		end
	elseif inside and input.middle == "pressed" then
		data.middle_scrolling = true
		data.middle_anchor_y = mouse_y
		stop_motion(data)
		if ctx.cursor then
			ctx.cursor:set_state("scroll")
		end
		input.interacting_with = elem
	end

	local right_held = input.right == "held" or input.right == "pressed"
	if data.right_scrolling then
		if right_held then
			local progress = clamp((mouse_y - rect.y) / rect.h, 0, 1)
			data.scroll_y = progress * data.max_scroll_y
			data.velocity = 0
			data.acceleration = 0
			data.snapping = false
		else
			data.right_scrolling = false
			input.interacting_with = nil
		end
	elseif inside and input.right == "pressed" then
		data.right_scrolling = true
		stop_motion(data)
		local progress = clamp((mouse_y - rect.y) / rect.h, 0, 1)
		data.scroll_y = progress * data.max_scroll_y
		input.interacting_with = elem
	end

	if inside and input.scroll_y and input.scroll_y ~= 0 then
		local wheel_delta = input.scroll_y > 0 and -1 or 1
		data.acceleration = 0
		if math.abs(data.horizontal_offset) < rect.w * HORIZONTAL_FULL_STRETCH_EPSILON then
			start_wheel_snap(data, elem_h, wheel_delta)
		end
		input.scroll_y = 0
	end

	local held = input.left == "held" or input.left == "pressed"
	if data.is_dragging then
		if held then
			local previous_drag_cursor_y = data.drag_cursor_y
			data.drag_cursor_x = mouse_x
			data.drag_cursor_y = mouse_y
			local drag_delta_y = data.drag_cursor_y - previous_drag_cursor_y
			local next_horizontal_offset = horizontal_drag_target(rect, data.drag_cursor_x)
			local scroll_factor = vertical_scroll_factor(rect, next_horizontal_offset)
			local next_scroll = data.scroll_y - drag_delta_y * scroll_factor
			if dt > 0 then
				local measured_velocity = (next_scroll - data.scroll_y) / dt
				data.acceleration = (measured_velocity - data.velocity) * DRAG_ACCELERATION
				data.velocity = data.velocity + data.acceleration * dt
				local measured_horizontal_velocity = (next_horizontal_offset - data.horizontal_offset) / dt
				data.horizontal_acceleration = (measured_horizontal_velocity - data.horizontal_velocity)
					* HORIZONTAL_DRAG_RESPONSE
				data.horizontal_velocity = data.horizontal_velocity + data.horizontal_acceleration * dt
			end
			if next_scroll ~= data.scroll_y then
				data.drag_direction = next_scroll > data.scroll_y and 1 or -1
			end
			-- for integrated_run
			-- print( "SPRING_LIST_CROSS", "x", mouse_x, "y", mouse_y, "delta_x", input.delta.x, "drag_delta_y", drag_delta_y, "rect", rect.x, rect.y, rect.w, rect.h, "res", ctx.res.w, ctx.res.h, "offset_before", data.horizontal_offset, "offset_after", next_horizontal_offset, "factor", scroll_factor, "velocity", data.velocity, "scroll_before", data.scroll_y, "scroll_after", next_scroll)
			data.scroll_y = next_scroll
			data.horizontal_offset = next_horizontal_offset
		else
			data.is_dragging = false
			input.interacting_with = nil
			data.horizontal_velocity = data.horizontal_velocity - data.horizontal_offset * HORIZONTAL_RELEASE_FORCE
			local drag_distance = data.drag_start_y - data.drag_cursor_y
			if drag_distance ~= 0 then
				data.drag_direction = drag_distance > 0 and 1 or -1
			end
			if math.abs(drag_distance) < elem_h and data.drag_direction ~= 0 then
				data.velocity = 0
				start_directional_snap(data, elem_h, data.drag_direction)
			end
		end
	elseif not data.middle_scrolling and inside and input.left == "pressed" then
		data.is_dragging = true
		data.drag_start_y = mouse_y
		data.drag_cursor_x = mouse_x
		data.drag_cursor_y = mouse_y
		data.drag_scroll_start_y = data.scroll_y
		data.drag_direction = 0
		stop_motion(data)
		input.interacting_with = elem
	end

	local fully_stretched = math.abs(data.horizontal_offset) >= rect.w * HORIZONTAL_FULL_STRETCH_EPSILON
	if fully_stretched and not data.is_dragging and not data.middle_scrolling and not data.right_scrolling then
		print(
			"SPRING_LIST_LOCK",
			"x",
			mouse_x,
			"offset",
			data.horizontal_offset,
			"velocity_before",
			data.velocity,
			"scroll",
			data.scroll_y
		)
	end
	if not data.is_dragging and not data.middle_scrolling and not data.right_scrolling and fully_stretched then
		data.acceleration = -data.velocity * VERTICAL_LOCK_DAMPING
		data.velocity = data.velocity + data.acceleration * dt
		data.scroll_y = data.scroll_y + data.velocity * dt
		if math.abs(data.velocity) < VERTICAL_LOCK_EPSILON then
			data.velocity = 0
			data.acceleration = 0
		end
	elseif not data.is_dragging and not data.middle_scrolling and not data.right_scrolling then
		update_motion(data, dt, elem_h)
	end
	update_horizontal_motion(data, dt)
	return data.scroll_y ~= old_scroll
		or data.horizontal_offset ~= old_horizontal_offset
		or data.drag_cursor_x ~= old_drag_cursor_x
		or data.drag_cursor_y ~= old_drag_cursor_y
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
		or data.right_scrolling
		or data.snapping
		or math.abs(data.velocity) > ACTIVE_VELOCITY_EPSILON
		or math.abs(data.horizontal_velocity) > HORIZONTAL_ACTIVE_VELOCITY_EPSILON
		or math.abs(data.horizontal_offset) > HORIZONTAL_ACTIVE_VELOCITY_EPSILON
		or (
			hit
			and (
				input.left == "pressed"
				or input.right == "pressed"
				or input.middle == "pressed"
				or input.scroll_y ~= 0
			)
		)
	if active and self:update_scroll(elem, ctx) then
		self:realign(ctx, elem)
	end
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

function spring_list:draw(elem, ctx, widget_data)
	local data = self:get_data(ctx)
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
