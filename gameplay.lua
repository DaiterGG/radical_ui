local class = require("class")

local gameplay = class()
gameplay.type = "gameplay"

function gameplay:new()
end

function gameplay:draw(elem, ctx)
	local rect = elem.rect
	if not rect then
		return
	end

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

	local api = ctx.gameplay_api
	if api and api.loaded then
		love.graphics.push("all")
		love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
		api:getSequenceView():draw()
		love.graphics.setScissor()
		love.graphics.pop()
	end
end

return gameplay
