local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")
local utils = require("utils")

-- text widget: renders a line of text with a font + color.
-- font name + size come from display data (data.font, data.size).
-- completely independent widget file.

local text = class()
text.type = "text"

function text:new(str)
	self.text = str or ""
end

-- function text:pointer_collision(elem, ctx, hit)
--   -- not interactive
-- end

function text:draw(elem, ctx, widget_data, entry)
	local r = elem.rect
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

	local tw = love.graphics.getFont():getWidth(self.text)
	local th = love.graphics.getFont():getHeight()

	-- horizontal
	local x
	if align_x == "right" then
		x = r.x + r.w - tw
	elseif align_x == "center" then
		x = r.x + (r.w - tw) / 2
	else
		x = r.x
	end

	-- vertical
	local y
	if align_y == "bottom" then
		y = r.y + r.h - th
	elseif align_y == "center" then
		y = r.y + (r.h - th) / 2
	else
		y = r.y
	end

	apply_display.draw_text(x, y, self.text, font, widget_data.color and { widget_data.color:to_rgba() })
end

return text
