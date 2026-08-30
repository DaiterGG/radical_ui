local apply_display = require("apply_display")
local class = require("class")
local ui_element = require("ui_element")

-- button widget: interactive (hover/press states).
-- optionally owns a child ui_element (text or icon element, created in the
-- view and passed to the builder); the button draws it and manages its state.
-- completely independent widget file.

local button = class()

function button:new(data)
  self.type = "button"
  self.on_press = data.action
  self.child = data.child
end

function button:pointer_collision(ctx, hit)
  local input = ctx.input_state

  -- when pressed, record this button as the widget being interacted with
  -- (so callers can do `self == ctx.input_state.interacting_with`)
  if hit and input.left == "pressed" then
    input.interacting_with = self
  end

  -- push the configured action into the action queue when clicked
  if self.on_press and hit and input.left == "pressed" then
    ctx.action_queue:register(self.on_press)
  end
end

function button:draw(elem, ctx, data, entry)
  local r = elem.rect
  if not data or not r then return end

  apply_display.draw_background(
    r.x, r.y, r.w, r.h,
    data.bg, data.border, entry and entry.polyline,
    { scale = ctx.ui_scale or 1 }
  )

  -- draw the owned child (text/icon) on top; its state mirrors the button's
  if self.child then
    self.child.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
    self.child.states = elem.states
    ui_element:draw(self.child, ctx)
  end
end

return button
