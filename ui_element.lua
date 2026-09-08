local class = require("class")
local utils = require("utils")
-- ui_element(opts)
-- opts: { display = display_key, widgets = {...}, align = Align(...), polyline = {...} }
-- display_key: string key from ctx.display_list
-- widgets: list of independent widget modules (box/button/slider)
-- align: optional alignment

-- unique per-element id, used to key ctx.input_state.interacting_with
local next_hash = 0

local ui_element = class()
ui_element.type = "ui_element"

function ui_element:new(opts)
	next_hash = next_hash + 1
	self.hash_num = next_hash
	self.display_key = opts.display
	self.widget = opts.widgets or {}
	self.align = opts.align
	self.polyline = opts.polyline
	self.children = {}
	self.rect = nil
	self.states = {
		idle = true,
		hovered = false,
		pressed = false,
		held = false,
		released = false,
	}
end

function ui_element:push_child(child)
	self.children[#self.children + 1] = child
end

local draw_order = {
	"idle",
	"hovered",
	"held",
	"pressed",
	"released",
}
-- draw one widget: if its display data is a state map (has an `idle` table)
-- iterate the element's active states, otherwise pass the plain data through.
function ui_element:draw_widget(w, ctx, widget_data, display_data)
	if not w.draw then
		return
	end
	if not widget_data then
		print("widget_data is not set: ", self.display_key)
		return
	end
	if not (widget_data and type(widget_data.idle) == "table") then
		w:draw(self, ctx, widget_data, display_data)
		return
	end
	for _, state_name in pairs(draw_order) do
		local active = self.states[state_name]
		local state_data = active and widget_data[state_name]
		if state_data then
			w:draw(self, ctx, state_data, display_data)
		end
	end
end

function ui_element:draw(ctx)
	local display_data = ctx.display_list[self.display_key]
	for _, w in ipairs(self.widget) do
		self:draw_widget(w, ctx, display_data and display_data[w.type], display_data)
	end
end

-- recursive variants (moved from ui_manager): a whole subtree can be aligned /
-- drawn / hit-tested by calling these on the root element, e.g. root:align_rec()

-- set this element's rect from its align + window, hand each child a fresh
-- window clipped to this rect, and recurse
function ui_element:align_rec(window, ctx)
	if self.align then
		local rect = self.align:apply(window, ctx.ui_scale)
		self.rect = rect
		window = { x = rect.x, y = rect.y, w = rect.w, h = rect.h }
	end
	for _, child in ipairs(self.children) do
		child:align_rec(window, ctx)
	end
end

-- draw this element, then recurse into children
function ui_element:draw_rec(ctx)
	self:draw(ctx)
	for _, child in ipairs(self.children) do
		child:draw_rec(ctx)
	end
end

-- recursive hit-test: this element's hit is passed down as parent_hit, so
-- children only react when an ancestor is hit
function ui_element:pointer_collision_rec(ctx, parent_hit)
	local hit = self:pointer_collision(ctx, parent_hit)
	for _, child in ipairs(self.children) do
		child:pointer_collision_rec(ctx, hit)
	end
end

function ui_element:pointer_collision(ctx, parent_hit)
	local rect = self.rect
	local hit = parent_hit
		and rect ~= nil
		and ctx.input_state.pos.x >= rect.x
		and ctx.input_state.pos.x < rect.x + rect.w
		and ctx.input_state.pos.y >= rect.y
		and ctx.input_state.pos.y < rect.y + rect.h

	-- update display states (idle stays active as the base)
	self.states.hovered = hit
	self.states.pressed = hit and ctx.input_state.left == "pressed"
	self.states.held = hit and ctx.input_state.left == "held"
	self.states.released = hit and ctx.input_state.left == "released"

	-- widget-specific logic (widgets take (elem, ctx, hit), elem = this element)
	for _, w in ipairs(self.widget) do
		if w.pointer_collision then
			w:pointer_collision(self, ctx, hit)
		end
	end

	return hit
end

return ui_element
