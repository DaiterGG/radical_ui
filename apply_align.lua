local class = require("class")

local Direction = {
  Left = "left",
  Right = "right",
  Up = "up",
  Down = "down",
}

local SizeTreatAs = {
  PercentOfHor = "PercentOfHor",
  PercentOfVert = "PercentOfVert",
  JustPixels = "JustPixels",
}

local Value = class()

-- Value("15")  -> percent: 15 out of 100 of the reference length
-- Value("5px") -> pixels: scaled by ui_scale
function Value:new(str)
  str = tostring(str)
  if str:sub(-2) == "px" then
    self.is_px = true
    self.value = tonumber(str:sub(1, -3)) or 0
  else
    self.is_px = false
    self.value = tonumber(str) or 0
  end
end

function Value:unwrap(length, ui_scale)
  if self.is_px then
    return self.value * (ui_scale or 1.0)
  end
  return (length * self.value) / 100
end

local Size = class()

-- Size({ percentOfHor = 30, percentOfVert = 30 }) -> % of parent
-- Size({ justPixels = 30 }) -> 30px for both axes (ui-scaled)
-- Size({ horPixels = 50, vertPixels = 40 }) -> independent pixel axes
-- percentOfHor/percentOfVert override their axis; horPixels/vertPixels set pixels per axis
function Size:new(opts)
  opts = opts or {}
  local px = opts.justPixels or 0
  local hor_px = opts.horPixels or px
  local vert_px = opts.vertPixels or px
  self.hor = opts.percentOfHor ~= nil and opts.percentOfHor or hor_px
  self.hor_type = opts.percentOfHor ~= nil and SizeTreatAs.PercentOfHor or SizeTreatAs.JustPixels
  self.vert = opts.percentOfVert ~= nil and opts.percentOfVert or vert_px
  self.vert_type = opts.percentOfVert ~= nil and SizeTreatAs.PercentOfVert or SizeTreatAs.JustPixels
end

function Size:unwrap(length_w, length_h, ui_scale)
  ui_scale = ui_scale or 1.0

  local function resolve(val, type_, ref_length)
    if type_ == SizeTreatAs.PercentOfHor then
      return (length_w * val) / 100
    elseif type_ == SizeTreatAs.PercentOfVert then
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

local Align = class()

function Align:block(direction, length)
  self.kind = "Block"
  self.direction = direction or Direction.Up
  self.length = length and Value(length) or Value("100")
  self._gap = Value("0")
  return self
end

function Align:absolute(opts)
  self.kind = "Absolute"
  opts = opts or {}
  self.pivot = opts.pivot or { x = 0, y = 0 }
  self.parent_pivot = opts.parent_pivot or { x = 0, y = 0 }
  self.size = opts.size or Size({ justPixels = 0 })
  return self
end

function Align:gap(new_gap)
  if self.kind == "Block" then
    self._gap = new_gap and Value(new_gap) or Value("0")
  else
    error("gap can only be applied to Block align")
  end
  return self
end

local function split_window(window, block_length, direction, ui_scale, gap_val)
  local block = {
    x = window.x,
    y = window.y,
    w = window.w,
    h = window.h,
  }

  ui_scale = ui_scale or 1.0

  -- left/right grow horizontally, up/down vertically;
  -- left/up take from the start edge, right/down from the end edge
  local horizontal = direction == Direction.Left or direction == Direction.Right
  local from_start = direction == Direction.Left or direction == Direction.Up

  local current_length = horizontal and window.w or window.h
  local gap_length = gap_val:unwrap(current_length, ui_scale)

  if horizontal then
    block.w = block_length:unwrap(current_length, ui_scale)

    if from_start then
      window.x = window.x + block.w + gap_length
    else
      block.x = window.x + (window.w - block.w)
    end

    window.w = window.w - block.w - gap_length
  else
    block.h = block_length:unwrap(current_length, ui_scale)

    if from_start then
      window.y = window.y + block.h + gap_length
    else
      block.y = window.y + (window.h - block.h)
    end

    window.h = window.h - block.h - gap_length
  end

  return block
end

-- window: input rect; ui_scale: optional
-- returns the computed rect
function Align:apply(window, ui_scale)
  ui_scale = ui_scale or 1.0

  if self.kind == "Block" then
    return split_window(window, self.length, self.direction, ui_scale, self._gap)
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

return {
  Align = Align,
  Value = Value,
  Size = Size,
  Direction = Direction,
  SizeTreatAs = SizeTreatAs,
}
