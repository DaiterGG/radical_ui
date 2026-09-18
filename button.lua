local apply_display = require("apply_display")
local class = require("class")
local ui_element = require("ui_element")
local utils = require("utils")
local widget = require("widget")

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
		self.on_hover = opts.on_hover
		self.on_release = opts.on_release
		self.on_any_release = opts.on_any_release
	end
	self.child = child
	self.hovered = false
end

function button:align(elem, ctx)
	widget.align(self, elem, ctx)
end

function button:pointer_collision(elem, ctx, hit)
	local input = ctx.input_state
	local hash = elem.hash_num
	if self.child then
		widget.set_child_states(self.child, elem.states)
	end

	if hit and input.left == "pressed" then
		input.interacting_with = hash
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

	if released and hit then
		-- print(released_and_hit, input.interacting_with, elem.hash_num)
	end

	if true_hit and not self.hovered and self.on_hover then
		ctx.action_queue:register(self.on_hover)
		input.interacting_with = elem.hash_num
	end
	self.hovered = true_hit
	if pressed_and_hit and self.on_press then
		ctx.action_queue:register(self.on_press)
	end
	if released_and_hit and interacting and self.on_release then
		ctx.action_queue:register(self.on_release)
	end

	if released_and_hit and (interacting or input.interacting_with == nil) and self.on_any_release then
		ctx.action_queue:register(self.on_any_release)
	end

	if not interacting and true_hit and held and self.on_hield then
		input.interacting_with = elem.hash_num
		ctx.action_queue:register(self.on_hield)
	end
	if not true_hit and (released or idle) and interacting then
		input.interacting_with = nil
	end

	elem.states.held = input.interacting_with == elem.hash_num
	if input.interacting_with == elem.hash_num then
		elem.states.selected = true
	end
end

function button:draw(elem, ctx, widget_display_data, display_data)
	local widget_data = widget_display_data
	local r = elem.rect

	if widget_data then
		apply_display.draw_background(widget_data, ctx, r, elem.polyline, elem)
	end

	-- draw the owned child (text/icon) on top; its state mirrors the button's
	if self.child then
		local r = elem.rect
		self.child.rect = { x = r.x, y = r.y, w = r.w, h = r.h }
		self.child:draw_rec(ctx)
	end
end

return button
