local utils = {}

local function json_escape(value)
	return tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

local function json_string(value)
	return '"' .. json_escape(value) .. '"'
end

local function is_array(t)
	local count = 0

	for k in pairs(t) do
		if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
			return false
		end
		count = count + 1
	end

	for i = 1, count do
		if t[i] == nil then
			return false
		end
	end

	return true
end

local function serialize(value, indent, seen)
	indent = indent or 0
	seen = seen or {}

	local prefix = string.rep("  ", indent)
	local next_prefix = string.rep("  ", indent + 1)

	if value == nil then
		return "null"
	elseif type(value) == "string" then
		return json_string(value)
	elseif type(value) == "number" or type(value) == "boolean" then
		return tostring(value)
	elseif type(value) ~= "table" then
		return json_string(value)
	end

	if seen[value] then
		return json_string("<circular>")
	end

	seen[value] = true

	local parts = {}

	if is_array(value) then
		for i = 1, #value do
			parts[#parts + 1] = next_prefix .. serialize(value[i], indent + 1, seen)
		end

		seen[value] = nil

		if #parts == 0 then
			return "[]"
		end

		return "[\n" .. table.concat(parts, ",\n") .. "\n" .. prefix .. "]"
	end

	for k, v in pairs(value) do
		parts[#parts + 1] = next_prefix .. json_string(k) .. ": " .. serialize(v, indent + 1, seen)
	end

	seen[value] = nil

	if #parts == 0 then
		return "{}"
	end

	return "{\n" .. table.concat(parts, ",\n") .. "\n" .. prefix .. "}"
end

function utils.print(value)
	print(serialize(value))
end

return utils
