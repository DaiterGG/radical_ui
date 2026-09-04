local function clamp(v)
  if v < 0 then
    return 0
  elseif v > 255 then
    return 255
  end
  return v
end

-- "#RRGGBB", "RRGGBB", "#RGB", 8-digit with alpha -> r, g, b, a
local function hex_digits(s)
  s = s:gsub("#", "")
  if #s == 3 or #s == 4 then
    s = s:gsub("(%x)", "%1%1")
  end
  if #s < 6 then
    return nil
  end
  return tonumber(s:sub(1, 2), 16),
      tonumber(s:sub(3, 4), 16),
      tonumber(s:sub(5, 6), 16),
      tonumber(s:sub(7, 8), 16)
end

local Color = {}
Color.__index = Color

-- color(r, g, b, a) | color(0xRRGGBB[AA]) | color("#RRGGBB[AA]") | color("#RRGGBB", alfa_percent)
--   alfa_percent: 0..100 alpha percent ("#RRGGBB" gets this alpha)
local function new(r, g, b, a)
  if type(r) == "string" then
    local hr, hg, hb, ha = hex_digits(r)
    if type(g) == "number" and b == nil then
      -- color("#RRGGBB", alfa_percent): second arg is alpha as a percent
      ha = (g / 100) * 255
    end
    r, g, b, a = hr, hg, hb, ha
  elseif g == nil then
    local v = math.floor(r)
    if v >= 0x1000000 then
      -- 0xRRGGBBAA
      a = v % 0x100
      b = math.floor(v / 0x100) % 0x100
      g = math.floor(v / 0x10000) % 0x100
      r = math.floor(v / 0x1000000) % 0x100
    else
      -- 0xRRGGBB
      a = 255
      b = v % 0x100
      g = math.floor(v / 0x100) % 0x100
      r = math.floor(v / 0x10000) % 0x100
    end
  end
  local c = setmetatable({}, Color)
  c.r, c.g, c.b, c.a = clamp(r), clamp(g), clamp(b), clamp(a or 255)
  return c
end

function Color:set(r, g, b, a)
  self.r, self.g, self.b = clamp(r), clamp(g), clamp(b)
  if a ~= nil then
    self.a = clamp(a)
  end
  return self
end

function Color:rgb(r, g, b)
  return self:set(r, g, b, self.a)
end

function Color:alpha(a)
  self.a = clamp(a)
  return self
end

local function lerp(x, y, t)
  return x + (y - x) * t
end

-- blend toward a color or a grayscale value; mutates self
function Color:blend(target, amount)
  local r, g, b
  if type(target) == "number" then
    r, g, b = target, target, target
  else
    r, g, b = target.r, target.g, target.b
  end
  self.r = clamp(lerp(self.r, r, amount))
  self.g = clamp(lerp(self.g, g, amount))
  self.b = clamp(lerp(self.b, b, amount))
  return self
end

-- tint: blend toward white (or another color); mutates self
function Color:tint(amount, target)
  return self:blend(target or 255, amount)
end

-- shade: blend toward black; mutates self
function Color:shade(amount)
  return self:blend(0, amount)
end

-- 0..1 components, ready for love.graphics
function Color:to_rgba()
  return self.r / 255, self.g / 255, self.b / 255, self.a / 255
end

function Color:hex()
  local s = string.format("%02X%02X%02X", self.r, self.g, self.b)
  if self.a < 255 then
    s = s .. string.format("%02X", self.a)
  end
  return s
end

function Color:clone()
  return new(self.r, self.g, self.b, self.a)
end

return new

-- local color = require("color")
-- local c = color("#FF0000"):tint(0.5):alpha(128)
-- print(c:hex())  -- "FF808080"
-- love.graphics.setFillColor(c:to_rgba())
