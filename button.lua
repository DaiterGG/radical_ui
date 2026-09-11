local apply_display = require("apply_display")
local class = require("class")
local ui_element = require("ui_element")
local utils = require("utils")

-- button widget: interactive (hover/press states).
-- optionally owns a child ui_element (text or icon element, created in the
-- view and passed to the builder); the button draws it and manages its state.
-- completely independent widget file.
-- child owned by the widget does not block the pointer collision
-- children owned by the ui_element does block the pointer collision

local button = class()
button.type = "button"

function button:new(child, opts)
	if opts then
		self.on_hield = opts.on_hield
		self.on_press = opts.on_press or self.on_hield
		self.on_release = opts.on_release
	end
	self.child = child
end

function button:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	local hash = elem.hash_num

	if hit and input.left == "pressed" then
		input.interacting_with = hash
		return
	end
end

-- called after all children had a chance to set interacting_with
function button:pointer_collision_after(elem, ctx, hit, children_hit)
	local input = ctx.input_state
	local interacting = input.interacting_with == elem.hash_num
	local true_hit = hit and not children_hit
	local pressed_and_hit = input.left == "pressed" and true_hit
	local released = input.left == "released"
	local idle = input.left == "idle"
	local held = input.left == "held"
	local released_and_hit = released and true_hit

	-- if input.left == "pressed" and interacting then
	-- 	print("click:", children_hit)
	-- end
	if pressed_and_hit and self.on_press then
		ctx.action_queue:register(self.on_press)
	end
	if released_and_hit and interacting and self.on_release then
		ctx.action_queue:register(self.on_release)
	end
	if not interacting and true_hit and held and self.on_hield then
		input.interacting_with = elem.hash_num
		ctx.action_queue:register(self.on_hield)
	end
	if not true_hit and (released or idle) and interacting then
		input.interacting_with = nil
	end
end

function button:draw(elem, ctx, widget_data, all_data)
	local r = elem.rect

	if widget_data then
		apply_display.draw_background(
			r,
			widget_data.bg,
			widget_data.border,
			elem.polyline,
			{ scale = ctx.ui_scale or 1 }
		)
	end

	-- draw the owned child (text/icon) on top; its state mirrors the button's
	if self.child then
		self.child.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
		self.child.states = elem.states
		self.child:draw(ctx)
	end
end

return button
