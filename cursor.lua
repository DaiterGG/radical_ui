local class = require("class")
local icons = require("icons")

local cursor = class()

function cursor:new(fonts)
	self.fonts = assert(fonts, "cursor requires the loaded font registry")
	self.state = "idle"
	self.size = 28
	self.color = { 0.8, 0.8, 0.8, 1 }
	self.color_outline = { 0, 0, 0, 1 }
	self.icons = {
		idle = { icons.idle2, icons.idle1 },
		scroll = { icons.scroll2, icons.scroll1 },
		hover = icons.hover,
		pressed = icons.press,
	}
	self.cursors = {}

	self:buffer_cursors()
	self:set_state(self.state)
end

function cursor:set_state(state)
	local native_cursor = assert(self.cursors[state], ("unknown cursor state: %s"):format(tostring(state)))
	self.state = state
	love.mouse.setCursor(native_cursor)
	return self
end

function cursor:draw_glyph(font, glyph, color)
	love.graphics.setColor(color)

	local width = font:getWidth(glyph)
	local height = font:getHeight()
	love.graphics.print(glyph, (self.size - width) / 2, (self.size - height) / 2)
end

function cursor:buffer_cursor(glyph)
	local font = assert(self.fonts:get("custom", self.size), "icons font is unavailable")
	local canvas = love.graphics.newCanvas(self.size, self.size)

	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.setFont(font)

	if type(glyph) == "table" then
		for index, layer in ipairs(glyph) do
			local layer_color = index == 1 and self.color_outline or self.color
			self:draw_glyph(font, layer, layer_color)
		end
	else
		self:draw_glyph(font, glyph, self.color)
	end

	love.graphics.setCanvas()
	love.graphics.pop()

	local image_data = canvas:newImageData()
	local native_cursor = love.mouse.newCursor(image_data, self.size / 2, self.size / 2)
	image_data:release()
	canvas:release()

	return native_cursor
end

function cursor:buffer_cursors()
	for state, glyph in pairs(self.icons) do
		self.cursors[state] = self:buffer_cursor(glyph)
	end
end

return cursor
