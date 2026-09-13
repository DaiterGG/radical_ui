-- fonts.lua: loads and registers the mod's UI fonts, with per-size caching.
-- usage:
--   local fonts = require("fonts")
--   fonts.load(init_font, mount_path)   -- resolve font file paths once
--   local f = fonts:get("awesome", 32)  -- love.Font at 32px (created + cached)
-- registry names correspond to the files in the fonts/ directory.

local fonts = {}

local fallback_file = "NotoSansCJK-Medium.ttc"
local fallback_multiplier = 0.8

-- name -> { file = <path under fonts/>, size = <px> }
local registrations = {
	icons = { file = "Glyphter.ttf", size = 20 },
	custom = { file = "Custom.ttf", size = 20 },
	afacad = { file = "Afacad-Regular.ttf", size = 20 },
	afacad_medium = { file = "Afacad-Medium.ttf", size = 20 },
	afacad_bold = { file = "Afacad-Bold.ttf", size = 20 },
	afacad_semibold = { file = "Afacad-SemiBold.ttf", size = 20 },
	noto_sans = { file = "NotoSans-Regular.ttf", size = 20 },
	noto_sans_thin = { file = "NotoSans-Thin.ttf", size = 20 },
	noto_sans_extra_light = { file = "NotoSans-ExtraLight.ttf", size = 20 },
	noto_sans_light = { file = "NotoSans-Light.ttf", size = 20 },
	noto_sans_medium = { file = "NotoSans-Medium.ttf", size = 20 },
	noto_sans_semibold = { file = "NotoSans-SemiBold.ttf", size = 20 },
	noto_sans_bold = { file = "NotoSans-Bold.ttf", size = 20 },
	noto_sans_extra_bold = { file = "NotoSans-ExtraBold.ttf", size = 20 },
	noto_sans_black = { file = "NotoSans-Black.ttf", size = 20 },
}

local paths = {} -- name -> resolved file path
local cache = {} -- "name:size" -> love.Font
local fallback_path
local fallback_cache = {}

local function join_path(mount_path, part)
	local p = mount_path or ""
	if p:sub(-1) ~= "/" and part:sub(1) ~= "/" then
		p = p .. "/"
	end
	return p .. part
end

local function find_font_path(file, mount_path)
	local candidates = {
		join_path(mount_path, "fonts/" .. file),
		"fonts/" .. file,
	}
	for _, path in ipairs(candidates) do
		local ok = pcall(love.graphics.newFont, path, 1)
		if ok then
			return path
		end
	end
end

local function get_fallback(size)
	if not fallback_path then
		return nil
	end
	if not fallback_cache[size] then
		local fallback_size = math.max(1, math.floor(size * fallback_multiplier + 0.5))
		local ok, font = pcall(love.graphics.newFont, fallback_path, fallback_size)
		if not ok then
			return nil
		end
		fallback_cache[size] = font
	end
	return fallback_cache[size]
end

local function add_fallback(font, path, size)
	if path ~= fallback_path then
		local fallback = get_fallback(size)
		if fallback then
			font:setFallbacks(fallback)
		end
	end
end

-- resolve each registered font's file path (missing files are skipped).
-- validation uses love.graphics.newFont (works for the mod's mounts) and
-- the default-size font is kept in the cache.
function fonts.load(init_font, mount_path)
	fonts.init = init_font
	fallback_path = find_font_path(fallback_file, mount_path)
	for name, reg in pairs(registrations) do
		local path = find_font_path(reg.file, mount_path)
		if path then
			local size = reg.size or 20
			local ok, font = pcall(love.graphics.newFont, path, size)
			if ok then
				add_fallback(font, path, size)
				paths[name] = path
				cache[name .. ":" .. tostring(size)] = font
			end
		end
	end
	return fonts
end

-- get a font at a size (created + cached on first request);
-- size defaults to the registration's default_size
function fonts:get(name, size)
	local reg = registrations[name]
	if not reg then
		return nil
	end
	size = size or reg.size or 20

	local key = name .. ":" .. tostring(size)
	if cache[key] == nil then
		local path = paths[name]
		if not path then
			return nil
		end
		local ok, font = pcall(love.graphics.newFont, path, size)
		if ok then
			add_fallback(font, path, size)
			cache[key] = font
		end
	end
	return cache[key]
end

-- get a font scaled by ui_scale.
-- target_size = math.floor(size * ui_scale + 0.5), clamped >= 1
-- returns scaled_font, target_size
function fonts:get_scaled(name, size, ui_scale)
	local s = ui_scale or 1
	size = size or (registrations[name] and registrations[name].size) or 20
	local target_size = math.max(1, math.floor(size * s + 0.5))
	return self:get(name, target_size), target_size
end

return fonts
