local input_state = {}

-- button state machine: "pressed" (this frame) | "held" | "released" (this frame) | "idle"
local function advance(state, is_down)
  if is_down then
    if state == "pressed" or state == "held" then
      return "held"
    end
    return "pressed"
  else
    if state == "pressed" or state == "held" then
      return "released"
    end
    return "idle"
  end
end

function input_state:new()
  return {
    updated = false,
    pos = { x = 0, y = 0 },
    delta = { x = 0, y = 0 },
    left = "idle", -- "pressed" | "held" | "released" | "idle"
    interacting_with = nil, -- widget object currently interacted with
    -- TODO: middle/right buttons, modifiers (shift/ctrl/alt), scroll
    scroll_y = 0,
  }
end

-- sample love input each frame (called by ui_manager.pointer_collision)
function input_state:poll(this)
  local mx, my = love.mouse.getPosition()
  if not this.updated then
    this.pos.x, this.pos.y = mx, my
    this.delta.x, this.delta.y = 0, 0
  else
    this.delta.x = mx - this.pos.x
    this.delta.y = my - this.pos.y
    this.pos.x, this.pos.y = mx, my
  end
  this.left = advance(this.left, love.mouse.isDown(1))
  -- clear interaction once the button is fully idle (mirrors InputState::reset)
  if this.left == "idle" then
    this.interacting_with = nil
  end
  this.updated = true
end

return input_state
