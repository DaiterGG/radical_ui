local utils = require("utils")
local color = require("color")

local apply_display = {}

-- general draw functions (shared by all element types).
-- no state management here; widget modules (box/button/slider) own their
-- display data and call these primitives from their own draw().
--
-- color arguments accept: a Color instance, a hex string ("#RRGGBB[AA]" /
-- "RRGGBB"), a 0xRRGGBB[AA] number, or an already-resolved rgba table; nil
-- skips the draw. resolve() turns all of them into a 0..1 rgba table for
-- love.graphics.setColor.

-- turn color-or-str (or rgba table) into a {r,g,b,a} 0..1 table; nil stays nil
local function resolve(c)
	if c == nil then
		return nil
	end
	if type(c) == "string" or type(c) == "number" then
		c = color(c)
	end
	if c.to_rgba then
		return { c:to_rgba() }
	end
	return c -- already an rgba table
end

-- draw a filled box
function apply_display.draw_box(x, y, w, h, c)
	c = resolve(c)
	if not c then
		return
	end
	love.graphics.setColor(c)
	love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), w, h)
end

-- draw a box border (outline).
--
-- single shared style: border = { width, radius, color, center = false }
--   default inner border (drawn inside the rect, not expanding outside);
--   set border.center = true to draw centered on the edge.
--
-- optional direction-specific borders (rectangular bg): give each edge its
-- own config instead of one shared style:
--   border = {
--     up    = { width = 2, color = c, center = true },
--     down  = { width = 2, color = c },
--     left  = { width = 2, color = c },
--     right = { width = 2, color = c },
--   }
--   any subset of the 4 edges may be given; each is drawn as a filled strip
--   along that edge (center = true straddles the edge, default stays inside).
function apply_display.draw_box_border(x, y, w, h, border, c)
	-- direction map form: detect per-edge configs (colors live per side, not
	-- in the shared `c` argument)
	if border and (border.up or border.down or border.left or border.right) then
		local function strip(side, sb)
			local bw = sb.width or 1
			local sc = resolve(sb.color)
			if not sc then
				return
			end
			local ox, oy, ow, oh
			if side == "up" then
				ox, ow, oh = x, w, bw
				oy = sb.center and y - bw / 2 or y
			elseif side == "down" then
				ox, ow, oh = x, w, bw
				oy = sb.center and y + h - bw / 2 or y + h - bw
			elseif side == "left" then
				oy, ow, oh = y, bw, h
				ox = sb.center and x - bw / 2 or x
			else -- right
				oy, ow, oh = y, bw, h
				ox = sb.center and x + w - bw / 2 or x + w - bw
			end
			love.graphics.setColor(sc)
			love.graphics.rectangle("fill", math.floor(ox + 0.5), math.floor(oy + 0.5), ow, oh)
		end
		for _, side in ipairs({ "up", "down", "left", "right" }) do
			if border[side] then
				strip(side, border[side])
			end
		end
		return
	end

	c = resolve(c)
	if not border or not c then
		return
	end
	local bw = border.width or 1
	local radius = border.radius or 0

	-- inner by default: inset rect so border draws inside
	-- center = true: draw centered on edge (no inset)
	local bx, by, bw_rect, bh_rect = x, y, w, h
	if not border.center then
		local inset = bw / 2
		bx, by = x + inset, y + inset
		bw_rect, bh_rect = w - bw, h - bw
	end

	love.graphics.setColor(c)
	love.graphics.setLineWidth(bw)
	love.graphics.rectangle("line", math.floor(bx + 0.5), math.floor(by + 0.5), bw_rect, bh_rect, radius, radius)
end

-- draw a filled box with rounded corners (radius in px, 0 = square)
function apply_display.corner_radius(x, y, w, h, radius, c)
	c = resolve(c)
	if not c then
		return
	end
	love.graphics.setColor(c)
	love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), w, h, radius or 0, radius or 0)
end

-- draw a filled polygon from points (local coords, offset by x,y)
function apply_display.draw_polygon(x, y, points, c)
	c = resolve(c)
	if not c or not points then
		return
	end
	local verts = {}
	for i, p in ipairs(points) do
		verts[#verts + 1] = math.floor(x + p[1] + 0.5)
		verts[#verts + 1] = math.floor(y + p[2] + 0.5)
	end
	love.graphics.setColor(c)
	love.graphics.polygon("fill", verts)
end

-- draw a polyline border (closed outline); no corner radius
-- if opts.center is true draws centered on edge; default inner (scaled inward).
function apply_display.draw_polyline(x, y, points, width, c, opts)
	c = resolve(c)
	if not c or not points then
		return
	end
	opts = opts or {}
	local w = width or 1
	local verts = {}

	-- inner by default: scale points toward centroid
	if not opts.center then
		local cx, cy = 0, 0
		for i, p in ipairs(points) do
			cx = cx + p[1]
			cy = cy + p[2]
		end
		local n = #points
		if n > 0 then
			cx, cy = cx / n, cy / n
			local scale = 1 - (w / (2 * math.max(w, cy))) -- conservative shrink factor
			scale = math.max(scale, 0)
			for i, p in ipairs(points) do
				verts[#verts + 1] = math.floor(x + cx + (p[1] - cx) * scale + 0.5)
				verts[#verts + 1] = math.floor(y + cy + (p[2] - cy) * scale + 0.5)
			end
		else
			return
		end
	else
		for i, p in ipairs(points) do
			verts[#verts + 1] = math.floor(x + p[1] + 0.5)
			verts[#verts + 1] = math.floor(y + p[2] + 0.5)
		end
	end

	love.graphics.setColor(c)
	love.graphics.setLineWidth(w)
	love.graphics.polygon("line", verts)
end

-- resolve polyline points into rect-local screen pixels.
-- each point may be:
--   { x_pc = n, y_pc = n }        percent of the rect w / h
--   { x_px = n, y_px = n }        ui-scaled pixels (raw px * scale)
--   { x_px = n, y_pc = n }        mixed per axis
--   { raw_x, raw_y }              legacy: raw px scaled by ui_scale
-- scale = ui_scale, w/h = rect size (needed for the % forms)
function apply_display.scale_points(points, scale, w, h)
	local out = {}
	for i, p in ipairs(points) do
		local px, py
		if p.x_px ~= nil or p.x_pc ~= nil or p.y_px ~= nil or p.y_pc ~= nil then
			-- keyed form: each axis is pixels (px * scale) or percent (w/h * n / 100)
			px = p.x_px ~= nil and p.x_px * scale or (p.x_pc ~= nil and w * p.x_pc / 100 or 0)
			py = p.y_px ~= nil and p.y_px * scale or (p.y_pc ~= nil and h * p.y_pc / 100 or 0)
		else
			-- legacy numeric pair: raw pixels scaled by ui_scale
			px, py = p[1] * scale, p[2] * scale
		end
		out[i] = { px, py }
	end
	return out
end

-- draw a background: bg fill + border. if polyline is provided it draws a
-- polygon (scaled by opts.scale) instead of a rect; opts.blur frosts the
-- background canvas region (opts.source) behind it.
-- opts: { scale = ui_scale, blur = { percent, blurSize }, source = canvas }
function apply_display.draw_background(rect, bg, border, polyline, opts)
	opts = opts or {}
	local scale = opts.scale or 1
	local x = rect.x
	local y = rect.y
	local w = rect.w
	local h = rect.h

	if polyline then
		local pts = apply_display.scale_points(polyline, scale, w, h)
		apply_display.draw_polygon(x, y, pts, bg)
		if border and border.color then
			apply_display.draw_polyline(x, y, pts, border.width, border.color, { center = border.center })
		end
		return
	end

	local radius = border and border.radius or 0
	if opts.blur and opts.source then
		apply_display.blur(opts.source, x, y, w, h, opts.blur)
	else
		apply_display.corner_radius(x, y, w, h, radius, bg)
	end

	if border and (border.color or border.up or border.down or border.left or border.right) then
		apply_display.draw_box_border(x, y, w, h, border, border.color)
	end
end

-- draw a line of text
function apply_display.draw_text(x, y, text, font, c)
	if not text then
		return
	end
	c = resolve(c)
	if font then
		love.graphics.setFont(font)
	end
	if c then
		love.graphics.setColor(c)
	end
	love.graphics.print(text, math.floor(x + 0.5), math.floor(y + 0.5))
end

-- -- draw an icon: a Font Awesome glyph or multi-char/ligature string
-- -- (e.g. a double-letter combination) rendered with the icon font
-- function apply_display.draw_icon(x, y, text, font, color_rgba)
--   if not text or not font then return end
--   love.graphics.setFont(font)
--   if color_rgba then
--     love.graphics.setColor(color_rgba)
--   end
--   love.graphics.print(text, x, y)
-- end

-- generic draw entry point (called by ui_manager).
-- delegates to the element's own draw method.
function apply_display.draw(elem, ctx)
	if elem and elem.draw then
		elem.draw(elem, ctx)
	end
end

-- gaussian blur shader (single-pass, 3x3 kernel)
local blur_shader = love.graphics.newShader([[
  extern number blurSize;
  extern number texW;
  extern number texH;

  vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    number dx = blurSize / texW;
    number dy = blurSize / texH;
    vec2 c = uv;
    vec4 sum = vec4(0.0);
    sum += Texel(tex, c + vec2(-dx, -dy)) * 0.0947416;
    sum += Texel(tex, c + vec2( 0.0, -dy)) * 0.118318;
    sum += Texel(tex, c + vec2( dx, -dy)) * 0.0947416;
    sum += Texel(tex, c + vec2(-dx,  0.0)) * 0.118318;
    sum += Texel(tex, c)                   * 0.147761;
    sum += Texel(tex, c + vec2( dx,  0.0)) * 0.118318;
    sum += Texel(tex, c + vec2(-dx,  dy)) * 0.0947416;
    sum += Texel(tex, c + vec2( 0.0,  dy)) * 0.118318;
    sum += Texel(tex, c + vec2( dx,  dy)) * 0.0947416;
    return sum * color;
  }
]])

-- low-res canvases cached by size, so we don't re-create them every frame
local lowres_cache = {}

-- blur the source (canvas/image) region (x, y, w, h) using a low-res
-- canvas + gaussian shader, then draw it back scaled up (like ui.Blur).
-- opts: percent (low-res scale, default 0.2), blurSize (pixels, default 1.5)
function apply_display.blur(source, x, y, w, h, opts)
	opts = opts or {}
	local percent = opts.percent or 0.2
	local blur_size = opts.blurSize or 1.5

	local cw = math.max(1, math.ceil(w * percent))
	local ch = math.max(1, math.ceil(h * percent))

	local canvas = lowres_cache[cw] and lowres_cache[cw][ch]
	if not canvas then
		canvas = love.graphics.newCanvas(cw, ch)
		lowres_cache[cw] = lowres_cache[cw] or {}
		lowres_cache[cw][ch] = canvas
	end

	local sw, sh = source:getDimensions()

	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	love.graphics.origin()
	love.graphics.clear()
	love.graphics.setShader(blur_shader)
	blur_shader:send("blurSize", blur_size)
	blur_shader:send("texW", sw)
	blur_shader:send("texH", sh)
	-- map the source rect (x,y,w,h) into the low-res canvas (0,0,cw,ch)
	love.graphics.draw(source, 0, 0, 0, cw / w, ch / h, x, y)
	love.graphics.setShader()
	love.graphics.pop()

	-- draw the low-res canvas back, scaled up to the original rect
	love.graphics.draw(canvas, x, y, 0, w / cw, h / ch)
end

return apply_display
