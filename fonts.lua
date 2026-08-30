-- fonts.lua: loads and registers the mod's UI fonts, with per-size caching.
-- usage:
--   local fonts = require("fonts")
--   fonts.load(mount_path)              -- resolve font file paths once
--   local f = fonts:get("awesome", 32)  -- love.Font at 32px (created + cached)
-- registry names: awesome, glyphter, ...

local fonts = {}

-- name -> { file = <path under fonts/>, size = <px> }
local registrations = {
  glyphter1_20 = { file = "Glyphter.ttf", size = 20 },
  -- add more fonts here, e.g.:
  -- awesome = { file = "Font Awesome 7 Brands-Regular-400.otf", size = 20 },
}

local paths = {} -- name -> resolved file path
local cache = {} -- "name:size" -> love.Font

local function join_path(mount_path, part)
  local p = mount_path or ""
  if p:sub(-1) ~= "/" and part:sub(1) ~= "/" then
    p = p .. "/"
  end
  return p .. part
end

-- resolve each registered font's file path (missing files are skipped).
-- validation uses love.graphics.newFont (works for the mod's mounts) and
-- the default-size font is kept in the cache.
function fonts.load(mount_path)
  for name, reg in pairs(registrations) do
    local candidates = {
      join_path(mount_path, "fonts/" .. reg.file),
      "fonts/" .. reg.file,
    }
    for _, p in ipairs(candidates) do
      local ok, font = pcall(love.graphics.newFont, p, reg.size or 20)
      if ok then
        paths[name] = p
        cache[name .. ":" .. tostring(reg.size or 20)] = font
        break
      end
    end
  end
end

-- get a font at a size (created + cached on first request);
-- size defaults to the registration's default_size
function fonts:get(name, size)
  local reg = registrations[name]
  if not reg then return nil end
  size = size or reg.size or 20

  local key = name .. ":" .. tostring(size)
  if cache[key] == nil then
    local path = paths[name]
    local ok, font = path and pcall(love.graphics.newFont, path, size)
    cache[key] = ok and font or nil
  end
  return cache[key]
end

return fonts
