local apply_display = require("apply_display")

local class = require("class")

-- box widget: plain box (background + border, optional blur, optional polyline).
-- completely independent widget file.

local box = class()

-- widget instance with custom data
function box:new()
end

function box:pointer_collision(ctx, hit)
  -- TODO: per-type interaction state
end

function box:draw(elem, ctx, data, entry)
  local r = elem.rect
  if not data or not r then return end

  apply_display.draw_background(
    r.x, r.y, r.w, r.h,
    data.bg, data.border, entry and entry.polyline,
    {
      blur = data.blur,
      source = ctx.ui.background_canvas,
      scale = ctx.ui_scale or 1,
    }
  )
end

return box
