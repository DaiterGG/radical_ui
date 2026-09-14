local utils = require("utils")
local color = require("color")

local apply_display = {}
local gradient_shader
local gradient_stencil

-- general draw functions (shared by all element types).
-- no state management here; widget modules (box/button) own their
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

local function ease_background(value, ease_name)
	if ease_name == "in" then
		return value * value
	elseif ease_name == "out" then
		return 1 - (1 - value) * (1 - value)
	elseif ease_name == "in_out" then
		if value < 0.5 then
			return 2 * value * value
		end
		return 1 - ((-2 * value + 2) ^ 2) / 2
	end
	return value
end

local function interpolate_background_color(from, target, amount)
	return {
		from[1] + (target[1] - from[1]) * amount,
		from[2] + (target[2] - from[2]) * amount,
		from[3] + (target[3] - from[3]) * amount,
		from[4] + (target[4] - from[4]) * amount,
	}
end

local function resolve_background(bg, ctx, elem)
	if type(bg) ~= "table" or (bg.in_color == nil and bg.from_color == nil) then
		return resolve(bg)
	end

	if bg.in_color == nil or bg.from_color == nil then
		error("animated background requires both 'in_color' and 'from_color'", 3)
	end

	local from = resolve(bg.from_color)
	local target = resolve(bg.in_color)
	if not from or not target then
		error("animated background colors must not be nil", 3)
	end
	if not ctx.state.ui_settings.animations then
		return target
	end

	local animation = elem and elem.display_animation
	if not animation then
		error("animated background requires ui_element.display_animation", 3)
	end
	if type(animation.key) ~= "string" or animation.key == "" then
		error("animated background requires a non-empty 'key'", 3)
	end
	if type(animation.duration) ~= "number" or animation.duration < 0 then
		error("animated background duration must be a non-negative number", 3)
	end
	if animation.ease ~= nil
		and animation.ease ~= "in"
		and animation.ease ~= "out"
		and animation.ease ~= "in_out"
	then
		error("animated background ease must be 'in', 'out', or 'in_out'", 3)
	end

	local registry = ctx and ctx.anim_reg and ctx.anim_reg[animation.key]
	if not registry then
		return target
	end

	local now = love.timer.getTime()
	local in_stamp = registry["in"] or 0
	local from_stamp = registry["from"] or 0
	if in_stamp <= 0 and from_stamp <= 0 then
		return target
	end

	local direction = from_stamp > in_stamp and "from" or "in"
	local stamp = registry[direction]
	if registry.background_transition_stamp ~= stamp then
		registry.background_transition_stamp = stamp
		registry.background_transition_started_at = now
	end

	local duration = animation.duration / 1000
	local progress = duration > 0
		and math.min(1, math.max(0, (now - registry.background_transition_started_at) / duration))
		or 1
	progress = ease_background(progress, animation.ease)
	if direction == "from" then
		return interpolate_background_color(target, from, progress)
	end
	return interpolate_background_color(from, target, progress)
end

local function vector_component(vector, index, key)
	if not vector then
		return 0
	end
	return vector[key] or vector[index] or 0
end

local function create_gradient_shader()
	return love.graphics.newShader([[
		extern vec2 gradientElementOrigin;
		extern vec2 gradientOrigin;
		extern vec2 gradientVector;
		extern vec4 gradientColor1;
		extern vec4 gradientColor2;
		extern vec4 gradientBackground;

		vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
			number lengthSquared = dot(gradientVector, gradientVector);
			number amount = 0.0;
			if (lengthSquared > 0.000001) {
				vec2 localCoords = screen_coords - gradientElementOrigin;
				amount = dot(localCoords - gradientOrigin, gradientVector) / lengthSquared;
			}
			amount = clamp(amount, 0.0, 1.0);
			vec4 gradientColor = vec4(
				mix(
					gradientColor1.rgb * gradientColor1.a,
					gradientColor2.rgb * gradientColor2.a,
					amount
				),
				mix(gradientColor1.a, gradientColor2.a, amount)
			);
			number inverseAlpha = 1.0 - gradientColor.a;
			number outputAlpha = gradientColor.a
				+ gradientBackground.a * inverseAlpha;
			vec3 outputRgb = gradientColor.rgb
				+ gradientBackground.rgb * gradientBackground.a * inverseAlpha;
			if (outputAlpha > 0.0) {
				outputRgb /= outputAlpha;
			}
			return vec4(
				outputRgb,
				outputAlpha
			) * color;
		}
	]])
end

local function get_gradient_shader()
	if not gradient_shader then
		gradient_shader = create_gradient_shader()
	end
	return gradient_shader
end

local function draw_gradient_stencil()
	if gradient_stencil.kind == "polygon" then
		apply_display.draw_polygon(
			gradient_stencil.x,
			gradient_stencil.y,
			gradient_stencil.points,
			{ 1, 1, 1, 1 }
		)
	else
		love.graphics.rectangle(
			"fill",
			gradient_stencil.x,
			gradient_stencil.y,
			gradient_stencil.w,
			gradient_stencil.h,
			gradient_stencil.radius,
			gradient_stencil.radius
		)
	end
end

local function draw_gradient_shape(rect, bg, gradient, polyline, scale, radius)
	if not gradient then
		return false
	end
	local color1 = resolve(gradient.color1 or gradient.from)
	local color2 = resolve(gradient.color2 or gradient.to)
	local background = resolve(bg)
	if not color1 or not color2 or not background then
		return false
	end

	local origin = gradient.origin or { x = 0, y = 0 }
	local direction = gradient.direction or {}
	local angle = math.rad(direction.angle or 0)
	local distance = direction.distance or 1
	local origin_x = vector_component(origin, 1, "x") * rect.w
	local origin_y = vector_component(origin, 2, "y") * rect.h
	local vector_x = math.cos(angle) * distance * rect.w
	local vector_y = math.sin(angle) * distance * rect.h
	local shader = get_gradient_shader()

	shader:send("gradientElementOrigin", { rect.x, rect.y })
	shader:send("gradientOrigin", { origin_x, origin_y })
	shader:send("gradientVector", { vector_x, vector_y })
	shader:send("gradientColor1", color1)
	shader:send("gradientColor2", color2)
	shader:send("gradientBackground", background)

	love.graphics.push("all")
	if not polyline and radius <= 0 then
		love.graphics.setShader(shader)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
		love.graphics.setShader()
		love.graphics.pop()
		return true
	end
	if polyline then
		love.graphics.setShader(shader)
		love.graphics.setColor(1, 1, 1, 1)
		apply_display.draw_polygon(
			rect.x,
			rect.y,
			apply_display.scale_points(polyline, scale),
			{ 1, 1, 1, 1 }
		)
		love.graphics.setShader()
		love.graphics.pop()
		return true
	end
	gradient_stencil = {
		kind = "rectangle",
		x = rect.x,
		y = rect.y,
		w = rect.w,
		h = rect.h,
		radius = radius,
	}
	love.graphics.stencil(draw_gradient_stencil, "replace", 1)
	love.graphics.setStencilTest("greater", 0)
	love.graphics.setShader(shader)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
	love.graphics.setShader()
	love.graphics.setStencilTest()
	love.graphics.pop()
	gradient_stencil = nil
	return true
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
	radius = math.min(radius, bw_rect / 2, bh_rect / 2)

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
	radius = math.min(radius or 0, w / 2, h / 2)
	love.graphics.setColor(c)
	love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), w, h, radius, radius)
end

-- draw a filled polygon from points (local coords, offset by x,y)
function apply_display.draw_polygon(x, y, points, c)
	c = resolve(c)
	if not c or not points or #points < 3 then
		return
	end

	local vertices = {}
	for _, point in ipairs(points) do
		local previous = vertices[#vertices]
		if not previous or previous[1] ~= point[1] or previous[2] ~= point[2] then
			vertices[#vertices + 1] = { point[1], point[2] }
		end
	end
	if #vertices > 2 then
		local first, last = vertices[1], vertices[#vertices]
		if first[1] == last[1] and first[2] == last[2] then
			vertices[#vertices] = nil
		end
	end

	local count = #vertices
	if count < 3 then
		return
	end

	local signed_area = 0
	for i = 1, count do
		local next_i = i % count + 1
		signed_area = signed_area
			+ vertices[i][1] * vertices[next_i][2]
			- vertices[next_i][1] * vertices[i][2]
	end
	local orientation = signed_area >= 0 and 1 or -1

	local function cross(a, b, c_point)
		return (b[1] - a[1]) * (c_point[2] - a[2])
			- (b[2] - a[2]) * (c_point[1] - a[1])
	end

	local function inside_triangle(point, a, b, c_point)
		local ab = cross(a, b, point) * orientation
		local bc = cross(b, c_point, point) * orientation
		local ca = cross(c_point, a, point) * orientation
		return ab >= -0.000001 and bc >= -0.000001 and ca >= -0.000001
	end

	local remaining = {}
	for i = 1, count do
		remaining[i] = i
	end

	love.graphics.setColor(c)
	local guard = count * count
	while #remaining > 3 and guard > 0 do
		local clipped = false
		for position = 1, #remaining do
			local previous_position = (position - 2) % #remaining + 1
			local next_position = position % #remaining + 1
			local a = vertices[remaining[previous_position]]
			local b = vertices[remaining[position]]
			local c_point = vertices[remaining[next_position]]
			if cross(a, b, c_point) * orientation > 0 then
				local contains_vertex = false
				for other_position, vertex_index in ipairs(remaining) do
					if other_position ~= previous_position
						and other_position ~= position
						and other_position ~= next_position
						and inside_triangle(vertices[vertex_index], a, b, c_point) then
						contains_vertex = true
						break
					end
				end
				if not contains_vertex then
					love.graphics.polygon("fill", {
						x + a[1], y + a[2],
						x + b[1], y + b[2],
						x + c_point[1], y + c_point[2],
					})
					table.remove(remaining, position)
					clipped = true
					break
				end
			end
		end
		if not clipped then
			break
		end
		guard = guard - 1
	end

	if #remaining == 3 then
		local a = vertices[remaining[1]]
		local b = vertices[remaining[2]]
		local c_point = vertices[remaining[3]]
		love.graphics.polygon("fill", {
			x + a[1], y + a[2],
			x + b[1], y + b[2],
			x + c_point[1], y + c_point[2],
		})
	end
end

-- draw a polyline border. Three or more points are treated as a closed
-- polygon, matching love.graphics.polygon. The border uses an inward offset,
-- so it never extends outside the supplied coordinates.
function apply_display.draw_polyline(x, y, points, width, c)
	c = resolve(c)
	if not c or not points or #points < 2 then
		return
	end
	local w = math.max(0, width or 1)
	if w == 0 then
		return
	end

	local vertices = {}
	for i, point in ipairs(points) do
		local previous = vertices[#vertices]
		if not previous or previous[1] ~= point[1] or previous[2] ~= point[2] then
			vertices[#vertices + 1] = { point[1], point[2] }
		end
	end

	local closed = #vertices > 2
	if closed then
		local first = vertices[1]
		local last = vertices[#vertices]
		if first[1] == last[1] and first[2] == last[2] then
			vertices[#vertices] = nil
		end
	end

	local count = #vertices
	if count < 2 then
		return
	end

	local function offset_line(a, b, nx, ny)
		return {
			x1 = a[1] + nx * (w / 2),
			y1 = a[2] + ny * (w / 2),
			x2 = b[1] + nx * (w / 2),
			y2 = b[2] + ny * (w / 2),
		}
	end

	local function line_intersection(a, b)
		local dx1, dy1 = a.x2 - a.x1, a.y2 - a.y1
		local dx2, dy2 = b.x2 - b.x1, b.y2 - b.y1
		local denominator = dx1 * dy2 - dy1 * dx2
		if math.abs(denominator) < 0.000001 then
			return { (a.x2 + b.x1) / 2, (a.y2 + b.y1) / 2 }
		end
		local t = ((b.x1 - a.x1) * dy2 - (b.y1 - a.y1) * dx2) / denominator
		return { a.x1 + dx1 * t, a.y1 + dy1 * t }
	end

	local lines = {}
	local segment_count = closed and count or count - 1
	local signed_area = 0
	if closed then
		for i = 1, count do
			local next_i = i % count + 1
			signed_area = signed_area
				+ vertices[i][1] * vertices[next_i][2]
				- vertices[next_i][1] * vertices[i][2]
		end
	end
	local inward_left = signed_area > 0

	for i = 1, segment_count do
		local next_i = i % count + 1
		local a, b = vertices[i], vertices[next_i]
		local dx, dy = b[1] - a[1], b[2] - a[2]
		local length = math.sqrt(dx * dx + dy * dy)
		if length > 0 then
			local left_x, left_y = -dy / length, dx / length
			if not closed or not inward_left then
				left_x, left_y = -left_x, -left_y
			end
			lines[i] = offset_line(a, b, left_x, left_y)
		end
	end

	love.graphics.setColor(c)
	local stroke = {}
	if closed then
		for i = 1, count do
			local previous_line = lines[(i - 2) % count + 1]
			local current_line = lines[i]
			if previous_line and current_line then
				stroke[#stroke + 1] = line_intersection(previous_line, current_line)
			end
		end
		if #stroke > 1 then
			stroke[#stroke + 1] = stroke[1]
		end
	else
		if lines[1] then
			stroke[#stroke + 1] = { lines[1].x1, lines[1].y1 }
		end
		for i = 1, segment_count do
			if lines[i] then
				stroke[#stroke + 1] = { lines[i].x2, lines[i].y2 }
			end
		end
	end

	if #stroke >= 2 then
		local line_vertices = {}
		for _, point in ipairs(stroke) do
			line_vertices[#line_vertices + 1] = x + point[1]
			line_vertices[#line_vertices + 1] = y + point[2]
		end
		love.graphics.setLineWidth(w)
		love.graphics.setLineJoin("miter")
		love.graphics.setLineStyle("smooth")
		love.graphics.line(line_vertices)
	end
end

-- resolve polyline points into rect-local screen pixels.
-- each point may be:
--   { raw_x, raw_y }              legacy: raw px scaled by ui_scale
--   { x_px = n, y_px = n }        explicit px values scaled by ui_scale
function apply_display.scale_points(points, scale)
	local out = {}
	for i, p in ipairs(points) do
		local px, py
		if p.x_px ~= nil or p.y_px ~= nil then
			px = (p.x_px or 0) * scale
			py = (p.y_px or 0) * scale
		else
			-- legacy numeric pair: raw pixels scaled by ui_scale
			px, py = p[1] * scale, p[2] * scale
		end
		out[i] = { px, py }
	end
	return out
end

local function get_points_bounds(x, y, points)
	if #points == 0 then
		return x, y, 0, 0
	end

	local min_x, min_y = math.huge, math.huge
	local max_x, max_y = -math.huge, -math.huge

	for _, point in ipairs(points) do
		min_x = math.min(min_x, point[1])
		min_y = math.min(min_y, point[2])
		max_x = math.max(max_x, point[1])
		max_y = math.max(max_y, point[2])
	end

	return x + min_x, y + min_y, max_x - min_x, max_y - min_y
end

-- draw a background: bg fill + border. if polyline is provided it draws a
-- polygon instead of a rect; widget_data supplies the display properties and
-- ctx supplies the background canvas and UI scale.
function apply_display.draw_background(widget_data, ctx, rect, polyline, elem)
	widget_data = widget_data or {}
	local bg = resolve_background(widget_data.bg, ctx, elem)
	local border = widget_data.border
	local scale = ctx.ui_scale or 1
	local x = rect.x
	local y = rect.y
	local w = rect.w
	local h = rect.h

	if polyline then
		local pts = apply_display.scale_points(polyline, scale)
		if ctx.state.ui_settings.blur and widget_data.blur and ctx.ui.background_canvas then
			local blur_x, blur_y, blur_w, blur_h = get_points_bounds(x, y, pts)
			if blur_w > 0 and blur_h > 0 then
				love.graphics.push("all")
				love.graphics.stencil(function()
					apply_display.draw_polygon(x, y, pts, { 1, 1, 1, 1 })
				end, "replace", 1)
				love.graphics.setStencilTest("greater", 0)
				apply_display.blur(
					ctx.ui.background_canvas,
					blur_x,
					blur_y,
					blur_w,
					blur_h,
					widget_data.blur
				)
				love.graphics.setStencilTest()
				love.graphics.pop()
			end
		end
		if not draw_gradient_shape(rect, bg, widget_data.gradient, polyline, scale, 0) then
			apply_display.draw_polygon(x, y, pts, bg)
		end
		if border and border.color then
			apply_display.draw_polyline(x, y, pts, border.width, border.color)
		end
		return
	end

	local radius = border and border.radius or 0
	if ctx.state.ui_settings.blur and widget_data.blur and ctx.ui.background_canvas then
		local blur = {}
		for key, value in pairs(widget_data.blur) do
			blur[key] = value
		end
		blur.cornerRadius = radius
		apply_display.blur(ctx.ui.background_canvas, x, y, w, h, blur)
	end
	if not draw_gradient_shape(rect, bg, widget_data.gradient, nil, scale, radius) then
		apply_display.corner_radius(x, y, w, h, radius, bg)
	end

	if border and (border.color or border.up or border.down or border.left or border.right) then
		apply_display.draw_box_border(x, y, w, h, border, border.color)
	end
end

-- draw a line of text
function apply_display.draw_text(x, y, text, font, c, scale)
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
	love.graphics.print(text, math.floor(x + 0.5), y, 0, scale or 1, scale or 1)
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

local function create_blur_shader(kernel_size)
	local center = (kernel_size - 1) / 2
	local sigma = kernel_size / 2
	local weights = {}
	local weight_total = 0

	for row = 0, kernel_size - 1 do
		for column = 0, kernel_size - 1 do
			local offset_x = column - center
			local offset_y = row - center
			local weight = math.exp(-(offset_x * offset_x + offset_y * offset_y) / (2 * sigma * sigma))
			weights[#weights + 1] = {
				offset_x = offset_x,
				offset_y = offset_y,
				weight = weight,
			}
			weight_total = weight_total + weight
		end
	end

	local shader_lines = {
		"  extern number blurSize;",
		"  extern number texW;",
		"  extern number texH;",
		"  extern number shapeW;",
		"  extern number shapeH;",
		"  extern number cornerRadius;",
		"",
		"  vec4 sampleBlur(Image tex, vec2 uv, vec2 offset, number weight) {",
		"    return Texel(tex, uv + offset) * weight;",
		"  }",
		"",
		"  vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {",
		"    number radius = min(cornerRadius, min(shapeW, shapeH) * 0.5);",
		"    vec2 point = screen_coords;",
		"    if (radius > 0.0) {",
		"      if (point.x < radius && point.y < radius",
		"          && distance(point, vec2(radius, radius)) > radius) {",
		"        discard;",
		"      }",
		"      if (point.x > shapeW - radius && point.y < radius",
		"          && distance(point, vec2(shapeW - radius, radius)) > radius) {",
		"        discard;",
		"      }",
		"      if (point.x < radius && point.y > shapeH - radius",
		"          && distance(point, vec2(radius, shapeH - radius)) > radius) {",
		"        discard;",
		"      }",
		"      if (point.x > shapeW - radius && point.y > shapeH - radius",
		"          && distance(point, vec2(shapeW - radius, shapeH - radius)) > radius) {",
		"        discard;",
		"      }",
		"    }",
		"",
		"    number dx = blurSize / texW;",
		"    number dy = blurSize / texH;",
		"    vec4 sum = vec4(0.0);",
	}

	for _, sample in ipairs(weights) do
		shader_lines[#shader_lines + 1] = string.format(
			"    sum += sampleBlur(tex, uv, vec2(%0.9f * dx, %0.9f * dy), %0.9f);",
			sample.offset_x,
			sample.offset_y,
			sample.weight / weight_total
		)
	end

	shader_lines[#shader_lines + 1] = ""
	shader_lines[#shader_lines + 1] = "    return sum * color;"
	shader_lines[#shader_lines + 1] = "  }"

	return love.graphics.newShader(table.concat(shader_lines, "\n"))
end

local blur_shaders = {}

local function resolve_kernel_size(value)
	if type(value) == "string" then
		local width, height = value:match("^%s*(%d+)%s*[xX]%s*(%d+)%s*$")
		if not width or width ~= height then
			error("blur dimensions must be a square size such as 3x3", 3)
		end
		value = tonumber(width)
	end
	return value
end

local function get_blur_shader(kernel_size)
	kernel_size = resolve_kernel_size(kernel_size)
	if type(kernel_size) ~= "number" or kernel_size < 1 or kernel_size ~= math.floor(kernel_size) then
		error("blur kernelSize must be a positive integer", 2)
	end
	if not blur_shaders[kernel_size] then
		blur_shaders[kernel_size] = create_blur_shader(kernel_size)
	end
	return blur_shaders[kernel_size]
end

-- low-res canvases cached by size, so we don't re-create them every frame
local lowres_cache = {}

-- blur the source (canvas/image) region (x, y, w, h) using a low-res
-- canvas + gaussian shader, then draw it back scaled up (like ui.Blur).
-- opts: percent (low-res scale, default 0.2), blurSize (pixels, default 1.5),
-- kernelSize (square shader kernel, default 3; e.g. 3 = 3x3, 4 = 4x4)
function apply_display.blur(source, x, y, w, h, opts)
	opts = opts or {}
	local percent = opts.percent or 0.2
	local blur_size = opts.blurSize or 1.5
	local kernel_size = opts.kernelSize or opts.dimensions or 8
	local opacity = opts.opacity or 1
	local blur_shader = get_blur_shader(kernel_size)

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
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setCanvas(canvas)
	love.graphics.origin()
	love.graphics.clear()
	love.graphics.setShader(blur_shader)
	blur_shader:send("blurSize", blur_size)
	blur_shader:send("texW", sw)
	blur_shader:send("texH", sh)
	blur_shader:send("shapeW", cw)
	blur_shader:send("shapeH", ch)
	blur_shader:send("cornerRadius", (opts.cornerRadius or 0) * percent)
	-- map the source rect (x,y,w,h) into the low-res canvas (0,0,cw,ch)
	love.graphics.draw(source, 0, 0, 0, cw / w, ch / h, x, y)
	love.graphics.setShader()
	love.graphics.pop()

	-- draw the low-res canvas back, scaled up to the original rect
	love.graphics.setColor(1, 1, 1, opacity)
	love.graphics.draw(canvas, x, y, 0, w / cw, h / ch)
end

return apply_display
