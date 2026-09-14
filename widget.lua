local widget = {}

local function widget_window(elem)
	local r = elem.rect
	return { x = r.x, y = r.y, w = r.w, h = r.h }
end

function widget.set_child_states(elem, states)
	elem.states = states
	for _, child in ipairs(elem.children) do
		widget.set_child_states(child, states)
	end
end

function widget.align(widget_instance, elem, ctx)
	if not widget_instance.child then
		return
	end

	local window = widget_window(elem)
	if widget_instance.child.align then
		widget_instance.child:align_rec(window, ctx)
	else
		widget_instance.child.rect = window
		for _, child in ipairs(widget_instance.child.children) do
			child:align_rec(widget_window(widget_instance.child), ctx)
		end
	end
end

return widget
