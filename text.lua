local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- text widget: renders text with a font + color.
-- font name + size come from display data (data.font, data.size).
-- completely independent widget file.

local text = class()
text.type = "text"

local default_line_gap = 4

function text:new(str, display_data)
	self.text = str or ""
	self.display_data = display_data
end

-- function text:pointer_collision(elem, ctx, hit)
--   -- not interactive
-- end

function text:draw(elem, ctx, widget_data, display_data)
	local r = elem.rect
	widget_data = widget_data
		or (display_data and display_data.font and display_data)
		or self.display_data
	if not widget_data or not r then
		return
	end

	local ui_scale = ctx and ctx.ui_scale
	local font = widget_data.font and fonts:get_scaled(widget_data.font, widget_data.size, ui_scale)
	if not font then
		return
	end

	-- alignment: optional, defaults to center/center
	local align_x = widget_data.align_x or "center" -- left, center, right
	local align_y = widget_data.align_y or "center" -- top, center, bottom

	love.graphics.setFont(font)

	local lines = {}
	for line in (self.text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	local font_height = love.graphics.getFont():getHeight()
	local line_gap = (widget_data.line_gap or default_line_gap) * (ui_scale or 1)
	local line_height = font_height + line_gap
	local block_height = font_height + (#lines - 1) * line_height

	local y
	if align_y == "bottom" then
		y = r.y + r.h - block_height
	elseif align_y == "center" then
		y = r.y + (r.h - block_height) / 2
	else
		y = r.y
	end

	for _, line in ipairs(lines) do
		local tw = love.graphics.getFont():getWidth(line)
		local x
		if align_x == "right" then
			x = r.x + r.w - tw
		elseif align_x == "center" then
			x = r.x + (r.w - tw) / 2
		else
			x = r.x
		end

		apply_display.draw_text(x, y, line, font, widget_data.color)
		y = y + line_height
	end
end

return text
