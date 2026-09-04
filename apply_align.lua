local class = require("class")
local utils = require("utils")

local Direction = {
	Left = "left",
	Right = "right",
	Up = "up",
	Down = "down",
}

local Size = class()
local Align = class()

-- Size API (matches quick-board pattern):
--   Size({ per_hor = 30, per_vert = 30 })         -> both axes as % of parent dimension
--   Size({ px_hor = 44, px_vert = 40 })           -> both axes as ui-scaled pixels
--   Size({ px_hor = 44, per_vert = 20 })          -> mixed: horizontal pixels, vertical percent
--   Size({ per = 30 })                            -> shortcut: both axes percent
--   Size({ px = 30 })                             -> shortcut: both axes pixels
function Size:new(opts)
	opts = opts or {}
	self.hor = opts.per_hor ~= nil and opts.per_hor or opts.px_hor or opts.per or opts.px or 0
	self.hor_type = opts.per_hor ~= nil and "PercentOfHor"
		or (opts.px_hor ~= nil or opts.px ~= nil or opts.per ~= nil) and "JustPixels"
		or "JustPixels"
	if opts.per ~= nil then
		self.hor_type = "PercentOfHor"
	end

	self.vert = opts.per_vert ~= nil and opts.per_vert or opts.px_vert or opts.per or opts.px or 0
	self.vert_type = opts.per_vert ~= nil and "PercentOfVert"
		or (opts.px_vert ~= nil or opts.px ~= nil or opts.per ~= nil) and "JustPixels"
		or "JustPixels"
	if opts.per ~= nil then
		self.vert_type = "PercentOfVert"
	end
end

function Size:unwrap(length_w, length_h, ui_scale)
	ui_scale = ui_scale or 1.0

	local function resolve(val, type_, ref_length)
		if type_ == "PercentOfHor" then
			return (length_w * val) / 100
		elseif type_ == "PercentOfVert" then
			return (length_h * val) / 100
		else
			return val * ui_scale
		end
	end

	return {
		w = resolve(self.hor, self.hor_type, length_w),
		h = resolve(self.vert, self.vert_type, length_h),
	}
end

function Align:block(direction, length)
	self.kind = "Block"
	self.direction = direction or Direction.Up
	self.length = length.pc or length.px
	self.length_type = length.px and "pixels" or "percent"
	self.gap = 0
	self.gap_type = "percent"
	return self
end

function Align:absolute(opts)
	self.kind = "Absolute"
	opts = opts or {}
	self.pivot = opts.pivot or { x = 0, y = 0 }
	self.parent_pivot = opts.parent_pivot or { x = 0, y = 0 }
	self.size = opts.size or Size({ px = 0 })
	return self
end

function Align:gap(new_gap)
	if self.kind == "Block" then
		self.gap = new_gap.pc or new_gap.px
		self.gap_type = new_gap.px and "pixels" or "percent"
	else
		error("gap can only be applied to Block align")
	end
	return self
end

function Align:split_window(window, ui_scale)
	utils.print(self)
	local block = {
		x = window.x,
		y = window.y,
		w = window.w,
		h = window.h,
	}

	ui_scale = ui_scale or 1.0

	local horizontal = self.direction == Direction.Left or self.direction == Direction.Right
	local from_start = self.direction == Direction.Left or self.direction == Direction.Up

	local current_length = horizontal and window.w or window.h
	local gap_length
	if self.gap_type == "pixels" then
		gap_length = self.gap * (ui_scale or 1.0)
	else
		gap_length = (current_length * self.gap) / 100
	end

	local block_len
	if self.length_type == "pixels" then
		block_len = self.length * (ui_scale or 1.0)
	else
		block_len = (current_length * self.length) / 100
	end

	if horizontal then
		block.w = block_len

		if from_start then
			window.x = window.x + block.w + gap_length
		else
			block.x = window.x + (window.w - block.w)
		end

		window.w = window.w - block.w - gap_length
	else
		block.h = block_len

		if from_start then
			window.y = window.y + block.h + gap_length
		else
			block.y = window.y + (window.h - block.h)
		end

		window.h = window.h - block.h - gap_length
	end

	return block
end

function Align:apply(window, ui_scale)
	ui_scale = ui_scale or 1.0

	if self.kind == "Block" then
		utils.print(self)
		return self:split_window(window, ui_scale)
	elseif self.kind == "Absolute" then
		local abs_size = self.size:unwrap(window.w, window.h, ui_scale)

		local align_x = (window.w * self.parent_pivot.x) / 100
		local pivot_x = (abs_size.w * self.pivot.x) / 100
		local new_x = window.x + align_x - pivot_x

		local align_y = (window.h * self.parent_pivot.y) / 100
		local pivot_y = (abs_size.h * self.pivot.y) / 100
		local new_y = window.y + align_y - pivot_y

		return { x = new_x, y = new_y, w = abs_size.w, h = abs_size.h }
	end

	error("unknown Align kind: " .. tostring(self.kind))
end

local function Absolute(opts)
	return Align():absolute(opts)
end

local function Block(direction, length)
	return Align():block(direction, length)
end

return {
	Align = Align,
	Size = Size,
	Direction = Direction,
	Absolute = Absolute,
	Block = Block,
}
