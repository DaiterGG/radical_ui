-- recursion lives in ui_element (align_rec / draw_rec / pointer_collision_rec);
-- the manager just drives the root elements.

local function align(ctx)
	if not ctx.state.need_to_realign then
		return
	end
	ctx.state.need_to_realign = false
	print("realign")
	local w, h = ctx.state.res.w or 800, ctx.state.res.h or 600

	for _, root in ipairs(ctx.state.root_elements) do
		local screen_window = { x = 0, y = 0, w = w, h = h }
		root:align_rec(screen_window, ctx)
	end
end

local function draw(ctx)
	for _, root in ipairs(ctx.state.root_elements) do
		root:draw_rec(ctx)
	end
end

local function pointer_collision(ctx)
	-- button states / per-frame deltas were driven by input_state:reset() at the
	-- end of the previous update, after this frame's events were fed
	local hit = false
	for i = #ctx.state.root_elements, 1, -1 do
		hit = ctx.state.root_elements[i]:pointer_collision_rec(ctx, not hit) or hit
		-- if hit then
		-- 	break
		-- end
	end
end

return { align = align, draw = draw, pointer_collision = pointer_collision }
