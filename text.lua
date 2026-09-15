local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")
local utils = require("utils")

-- text widget: renders text with a font + color.
-- font name + size come from display data (data.font, data.size).
-- completely independent widget file.

local text = class()
text.type = "text"

local default_line_gap = 4

local function clamp_line(line, font, max_width)
	if font:getWidth(line) <= max_width then
		return line
	end

	local suffix = "..."
	if font:getWidth(suffix) > max_width then
		return ""
	end

	line = line:sub(1, -2)
	while line ~= "" and font:getWidth(line .. suffix) > max_width do
		line = line:sub(1, -2)
	end

	return line .. suffix
end

function text:new(str, display_data)
	self.text = str or ""
	self.display_data = display_data
end

-- function text:pointer_collision(elem, ctx, hit)
--   -- not interactive
-- end

function text:draw(elem, ctx, widget_display_data, display_data)
	local widget_data = widget_display_data
	local r = elem.rect
	widget_data = widget_data or (display_data and display_data.font and display_data) or self.display_data
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

	local font_scale = 1
	local downscale = tonumber(widget_data.downscale)
	if downscale and downscale > 0 and downscale < 1 then
		local widest_line = 0
		for _, line in ipairs(lines) do
			widest_line = math.max(widest_line, font:getWidth(line))
		end
		if widest_line > r.w then
			font_scale = math.max(downscale, r.w / widest_line)
		end
	end

	for i, line in ipairs(lines) do
		lines[i] = clamp_line(line, font, r.w / font_scale)
	end

	local font_height = love.graphics.getFont():getHeight() * font_scale
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
		local tw = love.graphics.getFont():getWidth(line) * font_scale
		local x
		if align_x == "right" then
			x = r.x + r.w - tw
		elseif align_x == "center" then
			x = r.x + (r.w - tw) / 2
		else
			x = r.x
		end

		apply_display.draw_text(x, y, line, font, widget_data.color, font_scale)
		y = y + line_height
	end
end

return text
