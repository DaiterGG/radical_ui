local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- text widget: renders a line of text with a font + color.
-- font name + size come from display data (data.font, data.size).
-- completely independent widget file.

local text = class()

function text:new(str)
  self.type = "text"
  self.text = str or ""
end

function text:pointer_collision(ctx, hit)
  -- not interactive
end

function text:draw(elem, ctx, data, entry)
  local r = elem.rect
  if not data or not r then return end

  local font = data.font and fonts:get(data.font, data.size)
  if not font then return end

  apply_display.draw_text(r.x, r.y, self.text, font, data.color and { data.color:to_rgba() })
end

return text
