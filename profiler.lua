local profiler = {
	active = false,
	start_time = 0,
	checkpoint_time = 0,
	values = {},
}

function profiler.start()
	local now = love.timer.getTime()
	profiler.active = true
	profiler.start_time = now
	profiler.checkpoint_time = now
	profiler.values = {}
end

function profiler.checkpoint(group, label)
	if not profiler.active then
		return
	end

	local now = love.timer.getTime()
	profiler.values[#profiler.values + 1] = {
		group = group,
		label = label,
		elapsed = (now - profiler.checkpoint_time) * 1000,
	}
	profiler.checkpoint_time = now
end

function profiler.finish(threshold, groups)
	if not profiler.active or #groups == 0 then
		return
	end

	local total = (love.timer.getTime() - profiler.start_time) * 1000
	if total > threshold then
		local print_groups = {}
		if groups then
			for _, group in ipairs(groups) do
				print_groups[group] = true
			end
		end

		print("____________________")
		for _, value in ipairs(profiler.values) do
			if not groups or print_groups[value.group] then
				print(string.format("[%s] %s in: %.6f ms", value.group, value.label, value.elapsed))
			end
		end
		print(string.format("Update in: %.6f ms", total))
		print("____________________")
	end

	profiler.active = false
end

return profiler
