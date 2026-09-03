local execute = {
	quit = function()
		love.event.push("quit") -- same as the osu_ui example: the loop polls it and exits
	end,
	print_a = function()
		print("pressed button A")
	end,
	print_b = function()
		print("pressed button B")
	end,

	-- Gameplay
	pause_game = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.gameplayApi
		if api and api.loaded then
			api:pause()
		end
	end,
	resume_game = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.gameplayApi
		if api and api.loaded then
			api:play()
		end
	end,
	retry = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.gameplayApi
		if api and api.loaded then
			api:retry()
		end
	end,
	skip_intro = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.gameplayApi
		if api and api.loaded and api:canSkipIntro() then
			api:skipIntro()
		end
	end,
	increase_play_speed = function(action)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.gameplayApi
		if api and api.loaded then
			local dir = action.dir or 1
			api:increasePlaySpeed(dir)
		end
	end,

	-- Select / chart browser
	toggle_autoplay = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			local replay = api:getReplayBase()
			api:setAutoplay(not replay.autoplay)
		end
	end,
	remove_all_mods = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:removeAllMods()
		end
	end,
	play_preview = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:playPreview()
		end
	end,
	pause_preview = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:pausePreview()
		end
	end,
	toggle_preview = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			local src = api:getPreviewAudioSource()
			if src and src:isPlaying() then
				api:pausePreview()
			else
				api:playPreview()
			end
		end
	end,
	open_chart_directory = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:openChartDirectory()
		end
	end,
	export_osu_chart = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:exportOsuChart()
		end
	end,
	open_web_notechart = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:openWebNotechart()
		end
	end,

	-- Locations
	load_locations = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.locationsApi
		if api then
			api:loadLocations()
		end
	end,
	delete_chart_cache = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.locationsApi
		if api then
			api:deleteChartCache()
		end
	end,
	recalculate_scores = function()
		local api = SELECT_CONTEXT and SELECT_CONTEXT.locationsApi
		if api then
			api:recalculateScores()
		end
	end,
}

local function poll(ctx)
	local action = ctx.action_queue:pop()
	if not action then
		return
	end
	local fn = execute[action.action]
	if fn then
		fn(action)
	end
end

return poll
