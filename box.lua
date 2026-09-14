local apply_display = require("apply_display")

local class = require("class")

-- box widget: plain box (background + border, optional blur, optional polyline).
-- completely independent widget file.

local box = class()
box.type = "box"

-- widget instance with custom data
function box:new() end

-- function box:pointer_collision(elem, ctx, hit)
--   -- TODO: per-type interaction state
-- end

function box:draw(elem, ctx, widget_display_data, display_data)
	local widget_data = widget_display_data
	local r = elem.rect
	if not widget_data or not r then
		return
	end

	apply_display.draw_background(widget_data, ctx, r, elem.polyline, elem)
end

return box
