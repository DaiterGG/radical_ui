local class = require("class")

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

local input_state = class()

function input_state:new()
  self.pos = { x = 0, y = 0 }    -- pointer position (fed by mouse events)
  self.delta = { x = 0, y = 0 }  -- pointer movement this frame (fed by mousemoved)

  -- button state machines, driven in reset() from the raw down-state below
  self.left = "idle"             -- "pressed" | "held" | "released" | "idle"
  self.right = "idle"
  self.middle = "idle"

  -- raw down-state, fed by mouse events (event_handler.process)
  self.buttons = { left = false, right = false, middle = false, x1 = false, x2 = false }

  -- only modifiers are stored from the keyboard (fed by key events)
  self.modifiers = { shift = false, ctrl = false, alt = false, super = false }

  self.scroll_y = 0 -- vertical wheel delta this frame (fed by wheelmoved events)

  self.interacting_with = {} -- [hash_num] = element being interacted with; per-element managed
end

function input_state:reset()
  -- pointer position: always current (device query, never consumed)
  self.pos.x, self.pos.y = love.mouse.getPosition()

  -- raw button down-state: device query, never consumed
  self.buttons.left = love.mouse.isDown(1)
  self.buttons.right = love.mouse.isDown(2)
  self.buttons.middle = love.mouse.isDown(3)

  -- drive button state machines from the raw down-state
  self.left = advance(self.left, self.buttons.left)
  self.right = advance(self.right, self.buttons.right)
  self.middle = advance(self.middle, self.buttons.middle)

  -- per-frame deltas are cleared; wheel is fed by wheelmoved events during the
  -- frame and consumed by the scroller before this reset runs
  self.delta.x = 0
  self.delta.y = 0
  self.scroll_y = 0
end

return input_state
