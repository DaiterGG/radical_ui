local apply_display = require("apply_display")

-- slider widget: track + thumb, draggable value.
-- completely independent widget file.

local slider = {}
slider.__index = slider

-- widget instance with custom data (e.g. { min = 0, max = 100, value = 50 })
function slider:new()
  return setmetatable({}, slider)
end

function slider:pointer_collision(ctx, hit)
  -- TODO: drag handling (update value from thumb/mouse, ctx.input_state)
end

function slider:draw(elem, ctx)
  local display = ctx.display_list and ctx.display_list[elem.display_key]
  local this = display and display.slider
  local r = elem.rect
  if not r then return end

  -- track
  if this and this.bg then
    apply_display.draw_box(r.x, r.y, r.w, r.h, { this.bg:to_rgba() })
  end
  if this and this.border and this.border.color then
    apply_display.draw_box_border(r.x, r.y, r.w, r.h, this.border, { this.border.color:to_rgba() })
  end

  -- TODO: draw thumb based on self.data.value (and this.thumb_bg)
end

return slider
