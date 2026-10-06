local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- text_input widget: focuses on click, shows placeholder when empty/unfocused.
-- Does NOT own any child elements; all display is driven by its own config.
local text_input = class()
text_input.type = "text_input"

function text_input:select(widget, elem, input)
	widget.focused = true
	elem.states.selected = true
	elem.states.idle = false
	input.input_key = widget.registry_key
end

function text_input:deselect(elem, ctx, data)
	local input = ctx.input_state
	self.focused = false
	elem.states.selected = false
	elem.states.idle = true

	data.caret = #data.input_field + 1
	data.selection[1] = data.caret
	data.selection[2] = data.caret

	if input.input_key == self.registry_key then
		input.input_key = nil
	end
end

local function register_action(ctx, action_str, data)
	local action = { action = action_str }
	for key, value in pairs(data) do
		action[key] = value
	end
	ctx.action_queue:register(action)
end

function text_input:trigger_input(ctx, self_or_key, data)
	if not self_or_key or not data then
		return
	end
	local self_data = text_input:get_self(ctx, self_or_key)
	if self_data.on_input then
		register_action(ctx, self_data.on_input, data)
	else
		register_action(ctx, "default_keypress", data)
	end
	self_data.input_delay = self_data.input_delay_duration
end

function text_input:process_delay(ctx, widget, dt)
	if not widget.input_delay or widget.input_delay <= 0 then
		return
	end
	widget.input_delay = widget.input_delay - dt
	if widget.input_delay <= 0 and widget.on_input_with_delay then
		register_action(ctx, widget.on_input_with_delay, widget)
	end
end

function text_input:move_caret(ctx, widget_key, direction, modifiers)
	local data = ctx.widget_reg:get(widget_key)
	local text = data.input_field
	local caret = data.caret
	local extend = modifiers and modifiers.shift
	local ctrl = modifiers and modifiers.ctrl
	local target = caret + direction

	if ctrl then
		if direction < 0 then
			target = caret - 1
			while target > 0 and string.sub(text, target, target):match("%s") do
				target = target - 1
			end
			while target > 0 and not string.sub(text, target, target):match("%s") do
				target = target - 1
			end
			target = target + 1
		else
			target = caret
			while target <= #text and string.sub(text, target, target):match("%s") do
				target = target + 1
			end
			while target <= #text and not string.sub(text, target, target):match("%s") do
				target = target + 1
			end
		end
	end

	target = math.max(1, math.min(#text + 1, target))
	if extend then
		data.caret = target
		data.selection[2] = target
	else
		data.caret = target
		data.selection[1] = target
		data.selection[2] = target
	end
end

function text_input:get_self(ctx, self_or_key)
	return type(self_or_key) == "table" and self_or_key or ctx.widget_reg:get(self_or_key)
end
function text_input:select_all(ctx, self_or_key)
	local data = text_input:get_self(ctx, self_or_key)
	data.selection[1] = 1
	data.selection[2] = #data.input_field + 1
	data.caret = data.selection[2]
end

function text_input:selected_text(ctx, self_or_key)
	local data = text_input:get_self(ctx, self_or_key)
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	if start_pos == end_pos then
		return ""
	end
	return string.sub(data.input_field, start_pos, end_pos - 1)
end

function text_input:insert_text(ctx, widget_key, text)
	local data = ctx.widget_reg:get(widget_key)
	if text == nil then
		return data.input_field
	end
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	local after = string.sub(data.input_field, 1, start_pos - 1) .. text .. string.sub(data.input_field, end_pos)
	data.input_field = after
	data.caret = start_pos + #text
	data.selection[1] = data.caret
	data.selection[2] = data.caret
	return after
end

function text_input:set_text(ctx, widget_key, text)
	if text == nil then
		return
	end
	local data = ctx.widget_reg:get(widget_key)
	data.input_field = text
	data.caret = #text + 1
	data.selection[1] = data.caret
	data.selection[2] = data.caret
end

function text_input:caret_from_x(data, font, text_x, mouse_x)
	local text = data.input_field
	local caret = 1
	local best_distance = math.huge
	for index = 1, #text + 1 do
		local before = string.sub(text, 1, index - 1)
		local distance = math.abs(text_x + font:getWidth(before) - mouse_x)
		if distance < best_distance then
			best_distance = distance
			caret = index
		end
	end
	return caret
end

function text_input:text_origin(elem, data, widget_data, font)
	local text_width = font:getWidth(data.input_field)
	if widget_data.align_x == "left" then
		return elem.rect.x + (widget_data.pad_x or 4)
	end
	return elem.rect.x + (elem.rect.w - text_width) / 2
end

function text_input:set_mouse_selection(data, caret)
	data.caret = caret
	data.selection[2] = caret
end

function text_input:erase(ctx, widget_key, backward, ctrl)
	local data = ctx.widget_reg:get(widget_key)
	local before = data.input_field
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	if start_pos == end_pos then
		if backward then
			start_pos = data.caret - 1
			if ctrl then
				while start_pos > 0 and string.sub(data.input_field, start_pos, start_pos):match("%s") do
					start_pos = start_pos - 1
				end
				while start_pos > 0 and not string.sub(data.input_field, start_pos, start_pos):match("%s") do
					start_pos = start_pos - 1
				end
				start_pos = start_pos + 1
			end
			end_pos = data.caret
		else
			end_pos = data.caret + 1
			if ctrl then
				end_pos = data.caret
				while end_pos <= #data.input_field and string.sub(data.input_field, end_pos, end_pos):match("%s") do
					end_pos = end_pos + 1
				end
				while end_pos <= #data.input_field and not string.sub(data.input_field, end_pos, end_pos):match("%s") do
					end_pos = end_pos + 1
				end
			end
		end
	end
	start_pos = math.max(1, start_pos)
	end_pos = math.min(#data.input_field + 1, end_pos)
	local after = string.sub(data.input_field, 1, start_pos - 1) .. string.sub(data.input_field, end_pos)
	data.input_field = after
	data.caret = start_pos
	data.selection[1] = start_pos
	data.selection[2] = start_pos
	self:trigger_input(ctx, widget_key, { before = before, after = after })
end

function text_input:draw_markers(data, widget_data, font, x, y, height)
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	if start_pos ~= end_pos then
		local before = string.sub(data.input_field, 1, start_pos - 1)
		local selected = string.sub(data.input_field, start_pos, end_pos - 1)
		apply_display.draw_box(
			x + font:getWidth(before),
			y,
			font:getWidth(selected),
			height,
			widget_data.selection_color or "#FF0000"
		)
	end

	if data.focused then
		local before = string.sub(data.input_field, 1, data.caret - 1)
		apply_display.draw_box(
			x + font:getWidth(before),
			y,
			widget_data.caret_width or 1,
			height,
			widget_data.caret_color or widget_data.text_color or "#FFFFFF"
		)
	end
end

function text_input:get_widget_data(ctx)
	local data = ctx.widget_reg:get(self.registry_key)
	-- local widget_data_key = widget.registry_key
	-- local data = ctx.widget_reg:get(widget_data_key)

	if not data then
		data = {}
		data.input_field = self.starting_value or ""
		data.is_selected = false
		local text = data.input_field
		local caret = #text + 1
		data.selection = { caret, caret }
		data.caret = caret
		data.on_input = self.on_input
		data.on_finish_select = self.on_finish_select
		data.on_input_with_delay = self.on_input_with_delay
		data.input_delay_duration = self.input_delay or 0.5
		data.input_delay = 0
		ctx.widget_reg:set(self.registry_key, data)
	end
	if self.starting_value and self.starting_value ~= data.input_field then
		data.input_field = self.starting_value
		self.starting_value = nil
		data.caret = (#data.input_field + 1)
		data.selection[1] = data.caret
		data.selection[2] = data.caret
	end
	return data
end

-- constructor: text_input(placeholder_str, action, registry_key, options)
--   placeholder_str: hint text when empty and unfocused
--   action: called via action_queue when focus changes
--   options: { starting_value, auto_select, on_input, on_finish_select, on_input_with_delay, input_delay }
function text_input:new(placeholder_str, registry_key, options)
	if not registry_key then
		error("text_input requires a widget registry key")
	end
	options = options or {}
	self.placeholder = placeholder_str or ""
	self.registry_key = registry_key
	self.starting_value = options.starting_value
	self.auto_select = options.auto_select == true
	self.on_input = options.on_input
	self.on_finish_select = options.on_finish_select
	self.on_input_with_delay = options.on_input_with_delay
	self.input_delay = options.input_delay
	self.focused = false
end

function text_input:align(elem, ctx)
	local input = ctx.input_state
	if not self.focused and input.input_key == self.registry_key then
		-- print("was focused before rebuild -> Select")
		self.focused = true
		elem.states.selected = true
		elem.states.idle = false
	end
end

function text_input:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	local data = self:get_widget_data(ctx)
	local input_linked = input.input_key == self.registry_key
	if self.focused and input_linked and input.left == "pressed" and not hit then
		-- print("pressed out of focus -> deselect")
		self:deselect(elem, ctx, data)
	end
	if self.focused and not input_linked then
		-- print("not focused -> deselect")
		self:deselect(elem, ctx, data)
	end
	self:process_delay(ctx, data, ctx.state.last_delta or 0)
	local widget_data = ctx.display_list[elem.display_key] and ctx.display_list[elem.display_key][self.type]
	widget_data = widget_data and widget_data.idle and widget_data[self.focused and "selected" or "idle"] or widget_data

	if not widget_data or not widget_data.font then
		return
	end
	local font = fonts:get_scaled(widget_data.font, widget_data.size or widget_data.font_size, ctx.state.ui_scale)
	if not font then
		return
	end

	if hit and input.left == "pressed" then
		-- print("pressed -> select")
		self:select(self, elem, input)
		if self.auto_select then
			self:select_all(ctx, data)
		else
			data.mouse_selection_anchor =
				self:caret_from_x(data, font, self:text_origin(elem, data, widget_data, font), input.pos.x)
			data.caret = data.mouse_selection_anchor
			data.selection[1] = data.caret
			data.selection[2] = data.caret
		end
		return
	end

	if hit and input.input_key == self.registry_key and input.left == "held" and not self.auto_select then
		local caret = self:caret_from_x(data, font, self:text_origin(elem, data, widget_data, font), input.pos.x)
		self:set_mouse_selection(data, caret)
	end

	if input.input_key == self.registry_key and input.left == "released" and data.selection[1] ~= data.selection[2] then
		register_action(ctx, data.on_finish_select, data)
	end
end

function text_input:draw(elem, ctx, widget_display_data, display_data)
	local r = elem.rect
	if not widget_display_data or not r then
		return
	end
	local data = self:get_widget_data(ctx)

	local ui_scale = ctx and ctx.state.ui_scale
	local font = widget_display_data.font
		and fonts:get_scaled(
			widget_display_data.font,
			widget_display_data.size or widget_display_data.font_size,
			ui_scale
		)
	if not font then
		return
	end

	-- background / border
	local bg = widget_display_data.bg
	local border = widget_display_data.border or {}

	apply_display.draw_background({ bg = bg, border = border }, ctx, r, elem.polyline, elem)

	-- choose what to display: real text or placeholder
	local display_text = data.input_field
	if display_text == "" and not self.focused then
		display_text = self.placeholder
	end

	-- colors
	local text_color = widget_display_data.text_color or { r = 1, g = 1, b = 1 }
	local placeholder_color = widget_display_data.placeholder_color or "#FF0000"

	if display_text == self.placeholder then
		text_color = placeholder_color
	end

	-- padding (can be tuned in widget_data later)
	local pad_x = widget_display_data.pad_x or 4
	local pad_y = widget_display_data.pad_y or 2

	-- alignment: left or center only; center is default
	local align_x = widget_display_data.align_x or "center" -- "left" or "center"

	love.graphics.setFont(font)
	local tw = love.graphics.getFont():getWidth(display_text)
	local th = love.graphics.getFont():getHeight()

	local x
	if align_x == "left" then
		x = r.x + pad_x
	else
		x = r.x + (r.w - tw) / 2
	end

	local y = r.y + (r.h - th) / 2

	data.focused = self.focused
	self:draw_markers(data, widget_display_data, font, x, y, th)
	apply_display.draw_text(x, y, display_text, font, text_color)
end

return text_input
