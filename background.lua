local class = require("class")
local apply_display = require("apply_display")

-- background widget: draws the chart background image (produced by the game
-- from the chart, see ctx.game.backgroundModel) covering the element's rect.
-- renders into a shared canvas (ctx.ui.background_canvas) so other widgets
-- (e.g. box with a blur option) can blur what's behind them.
-- completely independent widget file.

local background = class()
background.type = "background"

function background:new()
end

-- function background:pointer_collision(elem, ctx, hit)
-- background is not interactive
-- end

-- draw an image covering the rect (centered, keep aspect ratio, cover)
local function draw_cover(image, x, y, w, h)
	local iw, ih = image:getDimensions()
	local scale = math.max(w / iw, h / ih)
	love.graphics.draw(image, x + w / 2, y + h / 2, 0, scale, scale, iw / 2, ih / 2)
end

function background:draw(elem, ctx, widget_display_data, display_data)
	local r = elem.rect
	if not r then
		return
	end

	local images = {}
	local alpha = 1
	if ctx.beatmaps then
		images = ctx.beatmaps:get_background_images()
		alpha = ctx.beatmaps:get_background_alpha()
	end

	-- (re)create the shared background canvas to match the element size
	local canvas = ctx.ui.background_canvas
	if not canvas or canvas:getWidth() ~= math.floor(r.w) or canvas:getHeight() ~= math.floor(r.h) then
		canvas = love.graphics.newCanvas(math.floor(r.w), math.floor(r.h))
		ctx.ui.background_canvas = canvas
	end

	-- render into the canvas (chart bg image, or configured color fallback)
	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	love.graphics.origin()
	love.graphics.clear()
	-- start with white so leaked setColor can't tint the canvas content
	love.graphics.setColor(1, 1, 1, 1)

	local has_background = ctx.state.ui_settings.background
		and (not ctx.beatmaps or ctx.beatmaps:has_background())
	if not has_background then
		local color = widget_display_data and widget_display_data.color
		apply_display.draw_box(0, 0, r.w, r.h, color)
	end

	if has_background and images[1] then
		draw_cover(images[1], 0, 0, r.w, r.h)
	end

	if has_background and images[2] then
		love.graphics.setColor(1, 1, 1, alpha)
		draw_cover(images[2], 0, 0, r.w, r.h)
		love.graphics.setColor(1, 1, 1, 1)
	end

	-- draw_test_pattern(r.w, r.h)
	love.graphics.pop()

	-- draw the canvas to screen; force white so a leaked setColor from other
	-- widgets can't tint the full-screen background
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas, r.x, r.y)
end

return background
