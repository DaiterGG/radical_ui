local class = require("class")
local utils = require("utils")
local animation_settings = require("animation_settings")

local Direction = {
	Left = "left",
	Right = "right",
	Up = "up",
	Down = "down",
}

local Size = class()
local Align = class()

-- Size API (matches quick-board pattern):
--   Size({ pc_hor = 30, pc_vert = 30 })          -> both axes as % of parent dimension
--   Size({ px_hor = 44, px_vert = 40 })           -> both axes as ui-scaled pixels
--   Size({ px_hor = 44, pc_vert = 20 })           -> mixed: horizontal pixels, vertical percent
--   Size({ px = 30 })                             -> shortcut: both axes pixels
function Size:new(opts)
	opts = opts or {}
	self.hor = opts.pc_hor ~= nil and opts.pc_hor or opts.px_hor or opts.px or 0
	self.hor_type = opts.pc_hor ~= nil and "PercentOfHor"
		or (opts.px_hor ~= nil or opts.px ~= nil) and "JustPixels"
		or "JustPixels"

	self.vert = opts.pc_vert ~= nil and opts.pc_vert or opts.px_vert or opts.px or 0
	self.vert_type = opts.pc_vert ~= nil and "PercentOfVert"
		or (opts.px_vert ~= nil or opts.px ~= nil) and "JustPixels"
		or "JustPixels"
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

function Align:animation(opts)
	opts = opts or {}
	self.animation_data = opts
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

local function clamp(value, min_value, max_value)
	return math.max(min_value, math.min(max_value, value))
end

local function ease(value, ease_fn)
	if type(ease_fn) == "function" then
		return ease_fn(value)
	elseif ease_fn == "in" then
		return value * value
	elseif ease_fn == "out" then
		return 1 - (1 - value) * (1 - value)
	elseif ease_fn == "in_out" then
		if value < 0.5 then
			return 2 * value * value
		end
		return 1 - ((-2 * value + 2) ^ 2) / 2
	end
	return value
end

local function mirror_ease(ease_fn)
	if ease_fn == "in" then
		return "out"
	elseif ease_fn == "out" then
		return "in"
	end
	return ease_fn
end

local function animation_ease(data, direction)
	local config = data.ease
	if type(config) == "table" then
		local selected = config[direction]
		if selected ~= nil then
			return selected
		end
		local other = direction == "in" and config.from or config["in"]
		return mirror_ease(other)
	end

	local selected = config or data.ease_fn
	if direction == "from" then
		return mirror_ease(selected)
	end
	return selected
end

local function apply_delta(rect, delta_pos, delta_size, amount, ui_scale)
	ui_scale = ui_scale or 1
	if delta_pos then
		rect.x = rect.x + (delta_pos.x or 0) * ui_scale * amount
		rect.y = rect.y + (delta_pos.y or 0) * ui_scale * amount
	end
	if delta_size then
		rect.w = rect.w + (delta_size.w or delta_size.x or 0) * ui_scale * amount
		rect.h = rect.h + (delta_size.h or delta_size.y or 0) * ui_scale * amount
	end
end

function Align:apply_animation(rect, ctx)
	local data = self.animation_data
	if not data or not ctx or not ctx.anim_reg then
		return rect
	end
	if animation_settings.is_disabled(ctx) then
		return rect
	end

	local registry = ctx.anim_reg[data.key]
	if not registry then
		return rect
	end
	registry.progress = registry.progress or 0

	local length = (data.length_ms or data.length or 0) / (data.length_ms and 1000 or 1)
	if length <= 0 then
		return rect
	end

	local now = love.timer.getTime()
	local in_stamp = registry["in"] or 0
	local from_stamp = registry["from"] or 0
	if in_stamp <= 0 and from_stamp <= 0 then
		return rect
	end

	local direction
	local stamp
	if from_stamp > in_stamp then
		direction = "from"
		stamp = from_stamp
	else
		direction = "in"
		stamp = in_stamp
	end

	if stamp ~= registry.transition_stamp then
		registry.transition_stamp = stamp
		registry.transition_progress = registry.progress
	end

	local target = direction == "from" and 1 or 0
	local distance = math.abs(target - registry.transition_progress)
	local animation_length = animation_settings.duration(ctx, length) * distance
	local elapsed = animation_length > 0 and clamp((now - registry.transition_stamp) / animation_length, 0, 1) or 1
	registry.progress = registry.transition_progress
		+ (target - registry.transition_progress) * ease(elapsed, animation_ease(data, direction))

	if elapsed < 1 and not animation_settings.is_instant(ctx) then
		ctx.state.need_to_realign = true
	end
	apply_delta(rect, data.delta_pos, data.delta_size, registry.progress, ctx.state.ui_scale)

	return rect
end

function Align:apply(window, ui_scale, ctx)
	ui_scale = ui_scale or 1.0

	if self.kind == "Block" then
		return self:split_window(window, ui_scale)
	elseif self.kind == "Absolute" then
		local abs_size = self.size:unwrap(window.w, window.h, ui_scale)

		local align_x = (window.w * self.parent_pivot.x) / 100
		local pivot_x = (abs_size.w * self.pivot.x) / 100
		local new_x = window.x + align_x - pivot_x

		local align_y = (window.h * self.parent_pivot.y) / 100
		local pivot_y = (abs_size.h * self.pivot.y) / 100
		local new_y = window.y + align_y - pivot_y

		return self:apply_animation({ x = new_x, y = new_y, w = abs_size.w, h = abs_size.h }, ctx)
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
