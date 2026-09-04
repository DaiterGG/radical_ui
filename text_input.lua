local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- text_input widget: focuses on click, shows placeholder when empty/unfocused.
-- Does NOT own any child elements; all display is driven by its own config.
-- No keyboard-handling yet; just focus semantics + drawing sketch.

local text_input = class()
text_input.type = "text_input"

-- constructor: text_input(placeholder_str, current_str, action)
--   placeholder_str: hint text when empty and unfocused
--   current_str: initial text value (empty = show placeholder)
--   action: called via action_queue when focus changes (and later, on edit)
function text_input:new(placeholder_str, current_str, action)
	self.placeholder = placeholder_str or ""
	self.current = current_str or ""
	self.action = action
	self.focused = false
end

function text_input:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state

	if hit and input.left == "pressed" and not self.focused then
		self.focused = true
		if self.action then
			ctx.action_queue:register(self.action, {
				event = "focus",
				text = self.current,
			})
		end
		return
	end
end

function text_input:draw(elem, ctx, widget_data, entry)
	local r = elem.rect
	if not widget_data or not r then
		return
	end

	local ui_scale = ctx and ctx.ui_scale
	local font = widget_data.font and fonts:get_scaled(widget_data.font, widget_data.size or widget_data.font_size, ui_scale)
	if not font then
		return
	end

	-- background / border
	local bg = widget_data.bg
	local border = widget_data.border or {}

	if self.focused then
		bg = widget_data.bg_focused or bg
		border = widget_data.border_focused or border
	end

	apply_display.draw_background(r, bg, border, entry and entry.polyline, { scale = ctx.ui_scale or 1 })

	-- choose what to display: real text or placeholder
	local display_text = self.current
	if display_text == "" and not self.focused then
		display_text = self.placeholder
	end

	-- colors
	local text_color = widget_data.text_color or { r = 1, g = 1, b = 1 }
	local placeholder_color = widget_data.placeholder_color or "#b07cf7"

	if display_text == self.placeholder then
		text_color = placeholder_color
	end

	-- padding (can be tuned in widget_data later)
	local pad_x = widget_data.pad_x or 4
	local pad_y = widget_data.pad_y or 2

	-- alignment: left or center only; center is default
	local align_x = widget_data.align_x or "center"  -- "left" or "center"

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

	apply_display.draw_text(x, y, display_text, font, text_color)
end

return text_input
