local hot_reload = {}

local function copy_table(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[key] = item
	end

	return setmetatable(copy, getmetatable(value))
end

local function copy_nested_table(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[key] = copy_nested_table(item)
	end

	return setmetatable(copy, getmetatable(value))
end

local function make_test_context(ctx)
	local test_ctx = copy_table(ctx)
	test_ctx.state = copy_table(ctx.state)
	test_ctx.state.res = copy_table(ctx.state.res)
	test_ctx.state.root_elements = {}
	test_ctx.state.need_to_rebuild = true
	test_ctx.settings = copy_nested_table(ctx.settings)
	test_ctx.beatmaps = copy_table(ctx.beatmaps)
	test_ctx.beatmaps.spring_list_data = copy_nested_table(ctx.beatmaps.spring_list_data)
	return test_ctx
end

local function is_lua_file(name)
	return name:sub(-4) == ".lua"
end

local function module_name(name)
	return "view." .. name:sub(1, -5)
end

local function scan_view_files(view_path)
	local files = {}
	local names = love.filesystem.getDirectoryItems(view_path)

	for _, name in ipairs(names) do
		if is_lua_file(name) then
			local path = view_path .. "/" .. name
			local info = love.filesystem.getInfo(path)
			if info then
				local content = love.filesystem.read(path)
				files[name] = {
					content = content,
				}
			end
		end
	end

	return files
end

local function view_files_changed(previous, current)
	for name, info in pairs(current) do
		local old_info = previous[name]
		if not old_info
			or old_info.content ~= info.content then
			return true
		end
	end

	for name in pairs(previous) do
		if not current[name] then
			return true
		end
	end

	return false
end

local function clear_view_modules(previous, current)
	for name in pairs(previous) do
		package.loaded[module_name(name)] = nil
	end

	for name in pairs(current) do
		package.loaded[module_name(name)] = nil
	end
end

function hot_reload.new(mount_path)
	return {
		view_path = mount_path .. "/view",
		files = scan_view_files(mount_path .. "/view"),
	}
end

function hot_reload.update(self, ctx)
	local files = scan_view_files(self.view_path)
	if not view_files_changed(self.files, files) then
		return nil
	end

	clear_view_modules(self.files, files)

	local style_ok, style = pcall(require, "view.style_display")
	if not style_ok then
		print("view hot reload failed:", style)
		return nil
	end

	local view_ok, reloaded_view = pcall(require, "view.view")
	if not view_ok then
		print("view hot reload failed:", reloaded_view)
		return nil
	end

	local test_ctx = make_test_context(ctx)
	local theme_ok, theme = pcall(style.theme)
	if not theme_ok then
		print("view hot reload failed:", theme)
		return nil
	end
	test_ctx.theme = theme

	local display_ok, display_list = pcall(style.display_data, test_ctx.theme)
	if not display_ok then
		print("view hot reload failed:", display_list)
		return nil
	end
	test_ctx.display_list = display_list

	local ok, error_message = pcall(reloaded_view, test_ctx)
	if not ok then
		print("view hot reload failed:", error_message)
		return nil
	end

	ctx.theme = test_ctx.theme
	ctx.display_list = test_ctx.display_list
	ctx.state.need_to_rebuild = true
	ctx.state.need_to_realign = true
	self.files = files

	return reloaded_view
end

return hot_reload
