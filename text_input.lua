local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- text_input widget: focuses on click, shows placeholder when empty/unfocused.
-- Does NOT own any child elements; all display is driven by its own config.
local text_input = class()
text_input.type = "text_input"

local function register_action(ctx, action, data, event)
	if not action then
		return
	end
	if type(action) == "string" then
		action = { action = action }
	end
	local queued = {}
	for key, value in pairs(action) do
		queued[key] = value
	end
	queued.event = event
	queued.text = data.input_field
	queued.input_data = data
	ctx.action_queue:register(queued)
end

function text_input:trigger_input(ctx, data)
	register_action(ctx, data.on_input, data, "input")
	data.input_delay = data.input_delay_duration
end

function text_input:process_delay(ctx, data, dt)
	if not data.input_delay or data.input_delay <= 0 then
		return
	end
	data.input_delay = data.input_delay - dt
	if data.input_delay <= 0 then
		register_action(ctx, data.on_input_with_delay, data, "input_with_delay")
	end
end

function text_input:move_caret(data, direction, modifiers)
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

function text_input:select_all(data)
	data.selection[1] = 1
	data.selection[2] = #data.input_field + 1
	data.caret = data.selection[2]
end

function text_input:selected_text(data)
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	if start_pos == end_pos then
		return ""
	end
	return string.sub(data.input_field, start_pos, end_pos - 1)
end

function text_input:insert_text(data, text)
	local start_pos = math.min(data.selection[1], data.selection[2])
	local end_pos = math.max(data.selection[1], data.selection[2])
	data.input_field = string.sub(data.input_field, 1, start_pos - 1)
		.. text
		.. string.sub(data.input_field, end_pos)
	data.caret = start_pos + #text
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

function text_input:erase(data, backward, ctrl)
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
				while end_pos <= #data.input_field
					and string.sub(data.input_field, end_pos, end_pos):match("%s")
				do
					end_pos = end_pos + 1
				end
				while end_pos <= #data.input_field
					and not string.sub(data.input_field, end_pos, end_pos):match("%s")
				do
					end_pos = end_pos + 1
				end
			end
		end
	end
	start_pos = math.max(1, start_pos)
	end_pos = math.min(#data.input_field + 1, end_pos)
	data.input_field = string.sub(data.input_field, 1, start_pos - 1)
		.. string.sub(data.input_field, end_pos)
	data.caret = start_pos
	data.selection[1] = start_pos
	data.selection[2] = start_pos
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
			widget_data.selection_color or "#5555AA"
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

local function get_widget_data(elem, ctx, widget)
	if not widget.registry_key then
		error("text_input requires a widget registry key")
	end
	local widget_data_key = widget.registry_key
	local data = ctx.widget_reg:get(widget_data_key)
	if not data then
		data = { input_field = "" }
		local text = data.input_field
		local caret = #text + 1
		data.selection = { caret, caret }
		data.caret = caret
		data.on_input = widget.on_input
		data.on_finish_select = widget.on_finish_select
		data.on_input_with_delay = widget.on_input_with_delay
		data.input_delay_duration = widget.input_delay or 0.5
		data.input_delay = 0
		ctx.widget_reg:set(widget_data_key, data)
	end
	return widget_data_key, data
end

-- constructor: text_input(placeholder_str, action, options)
--   placeholder_str: hint text when empty and unfocused
--   action: called via action_queue when focus changes
--   options: { registry_key, on_input, on_finish_select, on_input_with_delay, input_delay }
function text_input:new(placeholder_str, action, options)
	if not options or not options.registry_key then
		error("text_input requires a widget registry key")
	end
	self.placeholder = placeholder_str or ""
	self.action = action
	self.registry_key = options.registry_key
	self.on_input = options.on_input
	self.on_finish_select = options.on_finish_select
	self.on_input_with_delay = options.on_input_with_delay
	self.input_delay = options.input_delay
	self.focused = false
end

function text_input:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	local widget_data_key, data = get_widget_data(elem, ctx, self)
	if self.focused and input.input_key == widget_data_key
		and input.left == "pressed" and not hit
	then
		input.input_key = nil
	end
	if self.focused and input.input_key == nil then
		self.focused = false
		elem.states.selected = false
		data.caret = #data.input_field + 1
		data.selection[1] = data.caret
		data.selection[2] = data.caret
	end
	self:process_delay(ctx, data, ctx.dt or 0)
	local widget_data = ctx.display_list[elem.display_key]
		and ctx.display_list[elem.display_key][self.type]
	if not widget_data or not widget_data.font then
		return
	end
	local font = fonts:get_scaled(
		widget_data.font,
		widget_data.size or widget_data.font_size,
		ctx.ui_scale
	)
	if not font then
		return
	end

	if hit and input.left == "pressed" then
		self.focused = true
		input.input_key = widget_data_key
		elem.states.selected = true
		data.mouse_selection_anchor = self:caret_from_x(
			data,
			font,
			self:text_origin(elem, data, widget_data, font),
			input.pos.x
		)
		data.caret = data.mouse_selection_anchor
		data.selection[1] = data.caret
		data.selection[2] = data.caret
		if self.action then
			ctx.action_queue:register({
				action = self.action,
				event = "focus",
				text = data.input_field,
			})
		end
		return
	end

	if hit and input.input_key == widget_data_key and input.left == "held" then
		local caret = self:caret_from_x(
			data,
			font,
			self:text_origin(elem, data, widget_data, font),
			input.pos.x
		)
		self:set_mouse_selection(data, caret)
	end

	if input.input_key == widget_data_key and input.left == "released"
		and data.selection[1] ~= data.selection[2]
	then
		register_action(ctx, data.on_finish_select, data, "finish_select")
	end
end

function text_input:draw(elem, ctx, widget_display_data, display_data)
	local r = elem.rect
	if not widget_display_data or not r then
		return
	end
	local _, data = get_widget_data(elem, ctx, self)

	local ui_scale = ctx and ctx.ui_scale
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

	if elem.states.selected then
		bg = widget_display_data.selected_bg or bg
		border = widget_display_data.selected_border or border
	elseif self.focused then
		bg = widget_display_data.bg_focused or bg
		border = widget_display_data.border_focused or border
	end

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
