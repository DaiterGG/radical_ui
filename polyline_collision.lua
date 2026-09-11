local polyline_collision = {}

local EPSILON = 0.000001

local function point_coordinates(point, scale)
	if point.x_px ~= nil or point.y_px ~= nil then
		return (point.x_px or 0) * scale, (point.y_px or 0) * scale
	end
	return point[1] * scale, point[2] * scale
end

local function point_on_segment(px, py, ax, ay, bx, by)
	local ab_x, ab_y = bx - ax, by - ay
	local ap_x, ap_y = px - ax, py - ay
	local length_squared = ab_x * ab_x + ab_y * ab_y
	if length_squared <= EPSILON then
		local dx, dy = px - ax, py - ay
		return dx * dx + dy * dy <= EPSILON
	end

	local cross = ab_x * ap_y - ab_y * ap_x
	if math.abs(cross) > EPSILON then
		return false
	end

	local dot = ap_x * ab_x + ap_y * ab_y
	if dot < -EPSILON then
		return false
	end

	return dot <= length_squared + EPSILON
end

local function line_hit(px, py, points)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if point_on_segment(px, py, a[1], a[2], b[1], b[2]) then
			return true
		end
	end
	return false
end

function polyline_collision.contains(polyline, origin_x, origin_y, pointer_x, pointer_y, scale)
	if not polyline or #polyline < 2 then
		return false
	end

	scale = scale or 1
	local points = {}
	for i, point in ipairs(polyline) do
		local x, y = point_coordinates(point, scale)
		points[i] = { x, y }
	end

	local px, py = pointer_x - origin_x, pointer_y - origin_y
	if #points == 2 then
		return line_hit(px, py, points)
	end

	local inside = false
	local previous = points[#points]
	for _, current in ipairs(points) do
		if point_on_segment(px, py, previous[1], previous[2], current[1], current[2]) then
			return true
		end

		local crosses = (current[2] > py) ~= (previous[2] > py)
		if crosses then
			local intersection_x = (previous[1] - current[1]) * (py - current[2]) / (previous[2] - current[2])
				+ current[1]
			if px < intersection_x then
				inside = not inside
			end
		end
		previous = current
	end

	return inside
end

return polyline_collision
