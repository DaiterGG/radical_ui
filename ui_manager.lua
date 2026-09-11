-- recursion lives in ui_element (align_rec / draw_rec / pointer_collision_rec);
-- the manager just drives the root elements.

local function align(ctx)
	if not ctx.ui.need_to_realign then
		return
	end
	ctx.ui.need_to_realign = false
	local w, h = ctx.res.w or 800, ctx.res.h or 600
	local screen_window = { x = 0, y = 0, w = w, h = h }

	for i, root in ipairs(ctx.ui.root_elements) do
		root.align.index = i
		root:align_rec(screen_window, ctx)
	end
end

local function draw(ctx)
	for _, root in ipairs(ctx.ui.root_elements) do
		root:draw_rec(ctx)
	end
end

local function pointer_collision(ctx)
	-- button states / per-frame deltas were driven by input_state:reset() at the
	-- end of the previous update, after this frame's events were fed
	local hit = false
	for i = #ctx.ui.root_elements, 1, -1 do
		hit = ctx.ui.root_elements[i]:pointer_collision_rec(ctx, true) or hit
		-- if hit then
		-- 	break
		-- end
	end
end

return { align = align, draw = draw, pointer_collision = pointer_collision }
