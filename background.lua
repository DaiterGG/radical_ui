local class = require("class")

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

-- TODO: test-pattern hack so blur has something visible even without a chart
-- background; replace with the real background once backgroundModel exists
local function draw_test_pattern(w, h)
  love.graphics.setColor(0.1, 0.1, 0.2, 1)
  love.graphics.rectangle("fill", 0, 0, w, h)

  love.graphics.setColor(1, 0.2, 0.2, 1)
  love.graphics.circle("fill", w * 0.2, h * 0.3, h * 0.1)
  love.graphics.setColor(0.2, 1, 0.2, 1)
  love.graphics.circle("fill", w * 0.7, h * 0.2, h * 0.12)
  love.graphics.setColor(0.2, 0.4, 1, 1)
  love.graphics.rectangle("fill", w * 0.3, h * 0.6, w * 0.4, h * 0.2)
  love.graphics.setColor(1, 1, 0.2, 1)
  love.graphics.rectangle("fill", w * 0.08, h * 0.75, w * 0.16, h * 0.18)
  love.graphics.setColor(1, 0.6, 0.2, 1)
  love.graphics.circle("fill", w * 0.55, h * 0.85, h * 0.08)
end

function background:draw(elem, ctx)
  local r = elem.rect
  if not r then return end

  local bm = ctx.game and ctx.game.backgroundModel
  local has_bg = bm and bm.images and bm.images[1]

  -- (re)create the shared background canvas to match the element size
  local canvas = ctx.ui.background_canvas
  if not canvas
      or canvas:getWidth() ~= math.floor(r.w)
      or canvas:getHeight() ~= math.floor(r.h) then
    canvas = love.graphics.newCanvas(math.floor(r.w), math.floor(r.h))
    ctx.ui.background_canvas = canvas
  end

  -- render into the canvas (chart bg image, or test pattern as fallback)
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.origin()
  love.graphics.clear()
  -- start with white so leaked setColor can't tint the canvas content
  love.graphics.setColor(1, 1, 1, 1)

  if bm.images[1] then
    draw_cover(bm.images[1], 0, 0, r.w, r.h)
  end
  if bm.images[2] then
    local alpha = bm.alpha or 1
    love.graphics.setColor(1, 1, 1, alpha)
    draw_cover(bm.images[2], 0, 0, r.w, r.h)
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
