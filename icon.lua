local apply_display = require("apply_display")
local class = require("class")
local fonts = require("fonts")

-- icon widget: renders a Font Awesome icon (single glyph or a multi-char /
-- double-letter ligature string like "github") as text with the icon font.
-- font name + size come from display data (data.font, data.size).
-- completely independent widget file.

local icon = class()
icon.type = "icon"

-- text: the icon string (glyph or name/ligature)
function icon:new(text)
  self.text = text or ""
end

-- function icon:pointer_collision(elem, ctx, hit)
--   -- not interactive
-- end

function icon:draw(elem, ctx, data, entry)
  local r = elem.rect
  if not data or not r then return end

  local font = data.font and fonts:get(data.font, data.size)
  if not font then return end

  apply_display.draw_icon(r.x, r.y, self.text, font, data.color and { data.color:to_rgba() })
end

return icon
