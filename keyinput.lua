local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

local keybind_labels = {
	ctrl = "CT",
	shift = "SH",
	alt = "AL",
	super = "SU",
}

local keyinput = class()
keyinput.type = "keyinput"

local function format_keybind(key)
	local labels = {}
	local modifiers = {}
	for part in string.gmatch(key, "[^+]+") do
		modifiers[part] = true
	end
	local compact_modifiers = modifiers.ctrl and modifiers.shift and modifiers.alt
	for part in string.gmatch(key, "[^+]+") do
		if compact_modifiers and keybind_labels[part] then
			labels[#labels + 1] = string.sub(part, 1, 1):upper()
		else
			labels[#labels + 1] = keybind_labels[part] or string.upper(part)
		end
	end
	return table.concat(labels, "+")
end

function keyinput:new(action)
	if not action then
		error("keyinput requires an action")
	end
	self.action = action
	self.selected = false
end

function keyinput:select()
	self.selected = true
end

function keyinput:deselect()
	self.selected = false
end

function keyinput:get_value(ctx)
	local capture = ctx.input_state.keybind_capture
	if capture and capture.action == self.action then
		return "..."
	end
	for _, binding in ipairs(ctx.keybindings:list()) do
		if binding.action == self.action then
			return format_keybind(binding.keys[1] or "...")
		end
	end
	return "..."
end

function keyinput:align(elem, ctx)
	local capture = ctx.input_state.keybind_capture
	if capture and capture.action == self.action then
		self:select()
	else
		self:deselect()
	end
end

function keyinput:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	if hit and input.left == "pressed" then
		input.interacting_with = elem.hash_num
		ctx.action_queue:register({
			action = "keybind_capture",
			rebind = { action = self.action, pos = 1 },
		})
	end
end

function keyinput:pointer_collision_after(elem, ctx, hit, children_hit)
	local input = ctx.input_state
	local true_hit = hit and not children_hit
	local interacting = input.interacting_with == elem.hash_num
	elem.states.held = interacting
	elem.states.selected = self.selected or interacting
	if not true_hit and (input.left == "released" or input.left == "idle") and interacting then
		input.interacting_with = nil
	end
end

function keyinput:draw(elem, ctx, widget_display_data)
	local rect = elem.rect
	if not widget_display_data or not rect then
		return
	end
	apply_display.draw_background(widget_display_data, ctx, rect, elem.polyline, elem)
	local font = widget_display_data.font
		and fonts:get_scaled(widget_display_data.font, widget_display_data.size, ctx.state.ui_scale)
	if not font then
		return
	end
	local value = self:get_value(ctx)
	local padding = (widget_display_data.padding_hor or 0) * (ctx.state.ui_scale or 1)
	local available_width = math.max(0, rect.w - padding * 2)
	local font_scale = 1
	local downscale = tonumber(widget_display_data.downscale)
	local text_width = font:getWidth(value)
	if downscale and downscale > 0 and downscale < 1 and text_width > available_width then
		font_scale = math.max(downscale, available_width / text_width)
	end
	local scaled_width = text_width * font_scale
	local scaled_height = font:getHeight() * font_scale
	local x = rect.x + padding + (available_width - scaled_width) / 2
	local y = rect.y + (rect.h - scaled_height) / 2
	apply_display.draw_text(x, y, value, font, widget_display_data.color, font_scale)
end

return keyinput
