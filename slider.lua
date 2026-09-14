local apply_display = require("apply_display")
local class = require("class")
local widget = require("widget")

-- slider widget: horizontal value selector (0..1).
-- owns a ui_element handle (the thumb); the slider controls the handle rect
-- from its value and then aligns the handle subtree via align_rec.
-- dragging state lives on the widget instance (self.dragging); no widget_reg.
--
-- usage:
--   local ui_element = require("ui_element")
--   local slider = require("slider")
--   local box = require("box")
--   local handle = ui_element({
--     display = "slider_handle",
--     widgets = { box() },
--     align = absolute({
--       pivot = { x = 50, y = 50 },
--       parent_pivot = { x = 50, y = 50 },
--       size = Size({ px_hor = 24, px_vert = 24 }),
--     }),
--   })
--   track = ui_element({
--     display = "slider_track",
--     widgets = { slider(0.5, { action = "set_volume" }, handle) },
--     align = ...,
--   })
-- the queued action is a copy of the given action with `value` set to the
-- new slider value. handle size is resolved from handle.align when it is an
-- absolute align; otherwise the handle defaults to a square of track height.

local slider = class()
slider.type = "slider"

local function clamp01(value)
	return math.max(0, math.min(1, value))
end

local function copy_with_value(action, value)
	local queued = {}
	for key, field in pairs(action) do
		queued[key] = field
	end
	queued.value = value
	return queued
end

local function register_action(ctx, action, value)
	if action == nil then
		return
	end
	if type(action) == "string" then
		ctx.action_queue:register({ action = action, value = value })
		return
	end
	if type(action) ~= "table" then
		error("slider action must be a string, an action table, or a list of actions")
	end
	if action.action ~= nil then
		ctx.action_queue:register(copy_with_value(action, value))
		return
	end
	for _, single in ipairs(action) do
		register_action(ctx, single, value)
	end
end

local function value_from_pos(track, handle_w, pos_x)
	local span = track.w - handle_w
	if span <= 0 then
		return 0
	end
	return clamp01((pos_x - track.x - handle_w / 2) / span)
end

local function handle_size(handle, track, ui_scale)
	if handle.align ~= nil and handle.align.kind == "Absolute" and handle.align.size ~= nil then
		local size = handle.align.size:unwrap(track.w, track.h, ui_scale)
		return size.w, size.h
	end
	return track.h, track.h
end

local function align_handle_children(handle, ctx, window)
	for _, w in ipairs(handle.widget) do
		if w.align then
			w:align(handle, ctx)
		end
	end
	for _, child in ipairs(handle.children) do
		child:align_rec(window, ctx)
	end
end

local function refresh_value(self, ctx, track, pos_x)
	local handle_w = track.h
	if self.child.rect ~= nil and self.child.rect.w ~= nil then
		handle_w = self.child.rect.w
	end
	local next_value = value_from_pos(track, handle_w, pos_x)
	if next_value ~= self.value then
		self.value = next_value
		register_action(ctx, self.action, next_value)
	end
end

function slider:new(value, action, child)
	if type(value) ~= "number" then
		error("slider requires a numeric value")
	end
	if action == nil then
		error("slider requires an action")
	end
	if child == nil then
		error("slider requires a handle child ui_element")
	end
	self.value = clamp01(value)
	self.action = action
	self.child = child
	self.dragging = false
end

function slider:align(elem, ctx)
	local track = elem.rect
	if track == nil then
		error("slider:align requires elem.rect to be set")
	end
	if self.child == nil then
		error("slider:align requires a handle child ui_element")
	end
	if type(self.value) ~= "number" then
		error("slider value must be a number")
	end
	local ui_scale = ctx.ui_scale or 1
	local handle_w, handle_h = handle_size(self.child, track, ui_scale)
	if handle_w > track.w then
		handle_w = track.w
	end
	if handle_h > track.h then
		handle_h = track.h
	end
	self.value = clamp01(self.value)
	local x = track.x + self.value * (track.w - handle_w)
	local y = track.y + (track.h - handle_h) / 2
	-- own the handle rect, then align its subtree via align_rec
	self.child.rect = { x = x, y = y, w = handle_w, h = handle_h }
	local window = { x = x, y = y, w = handle_w, h = handle_h }
	align_handle_children(self.child, ctx, window)
end

function slider:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	if input == nil then
		error("slider:pointer_collision requires ctx.input_state")
	end
	local track = elem.rect
	if track == nil then
		return
	end
	if hit and input.left == "pressed" then
		input.interacting_with = elem.hash_num
		self.dragging = true
		refresh_value(self, ctx, track, input.pos.x)
	end
end

function slider:pointer_collision_after(elem, ctx, hit, children_hit)
	if not self.dragging then
		return
	end
	local input = ctx.input_state
	if input == nil then
		error("slider:pointer_collision_after requires ctx.input_state")
	end
	local track = elem.rect
	if track == nil then
		return
	end
	local interacting = input.interacting_with == elem.hash_num
	if input.left == "held" then
		if interacting then
			input.interacting_with = elem.hash_num
			refresh_value(self, ctx, track, input.pos.x)
		end
	elseif input.left == "released" then
		if interacting then
			refresh_value(self, ctx, track, input.pos.x)
			input.interacting_with = nil
		end
		self.dragging = false
	elseif input.left == "idle" then
		if not interacting then
			self.dragging = false
		end
	end
	if self.dragging then
		elem.states.selected = true
	end
end

function slider:draw(elem, ctx, widget_display_data, display_data)
	local r = elem.rect
	if not r then
		return
	end

	if widget_display_data then
		apply_display.draw_background(widget_display_data, ctx, r, elem.polyline, elem)
	end

	-- draw the owned handle on top; its state mirrors the slider track
	if self.child then
		widget.set_child_states(self.child, elem.states)
		self.child:draw_rec(ctx)
	end
end

return slider
