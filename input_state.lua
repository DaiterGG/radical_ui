local class = require("class")

-- button state machine: "pressed" (this frame) | "held" | "released" (this frame) | "idle"
local function advance(state)
	if state == "pressed" then
		return "held"
	elseif state == "released" then
		return "idle"
	end
	return state
end

local input_state = class()

function input_state:new()
	self.pos = { x = 0, y = 0 } -- pointer position (fed by mouseposition/mousemoved events via event_handler)
	self.delta = { x = 0, y = 0 } -- pointer movement this frame (fed by mousemoved via event_handler)

	-- button state machines, driven in reset() from the raw down-state below
	self.button_names = { "left", "right", "middle", "mouse4", "mouse5" }
	self.left = "idle" -- "pressed" | "held" | "released" | "idle"
	self.right = "idle"
	self.middle = "idle"
	self.mouse4 = "idle"
	self.mouse5 = "idle"

	-- only modifiers are stored from the keyboard (fed by key events via event_handler)
	self.modifiers = { shift = false, ctrl = false, alt = false, super = false }

	self.scroll_y = 0 -- vertical wheel delta this frame (fed by wheelmoved via event_handler)

	self.interacting_with = {} -- [hash_num] = element being interacted with; per-element managed
end

function input_state:reset()
	-- drive button state machines from the raw down-state (set by event_handler from events)
	self.left = advance(self.left)
	self.right = advance(self.right)
	self.middle = advance(self.middle)
	self.middle = advance(self.middle)

	-- per-frame deltas are cleared; wheel is fed by wheelmoved events during the
	-- frame and consumed by the scroller before this reset runs
	self.delta.x = 0
	self.delta.y = 0
	self.scroll_y = 0
end

return input_state
