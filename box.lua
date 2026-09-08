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

function box:draw(elem, ctx, widget_data, all_data)
	local r = elem.rect
	if not widget_data or not r then
		return
	end

	apply_display.draw_background(r, widget_data.bg, widget_data.border, elem.polyline, {
		blur = widget_data.blur,
		source = ctx.ui.background_canvas,
		scale = ctx.ui_scale or 1,
	})
end

return box
