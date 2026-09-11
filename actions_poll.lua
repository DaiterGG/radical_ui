local execute
execute = {
	quit = function(ctx)
		if ctx.ui.scene == "gameplay" then
			execute.stop_gameplay(ctx)
			return
		end
		love.event.push("quit") -- same as the osu_ui example: the loop polls it and exits
	end,
	select_beatmap = function(ctx, data)
		ctx.beatmaps:select(data.index)
	end,
	start_gameplay = function(ctx)
		if ctx.ui.scene == "gameplay" then
			return
		end

		ctx.beatmaps:ensure_loaded()
		if not ctx.game.selectModel:notechartExists() then
			return
		end

		ctx.gameplay_api:start()
		ctx.ui.scene = "gameplay"
		ctx.ui.need_to_rebuild = true
		ctx.ui.need_to_realign = true
	end,
	stop_gameplay = function(ctx)
		if ctx.ui.scene ~= "gameplay" then
			return
		end

		ctx.gameplay_api:stop()
		ctx.ui.scene = "select"
		ctx.ui.need_to_rebuild = true
		ctx.ui.need_to_realign = true
	end,
	ui_scale_custom = function(ctx, new_scale)
		ctx.ui.custom_scale = new_scale
		ctx.ui.need_to_realign = true
	end,
	print_b = function(ctx)
		print("pressed button B")
	end,
	settings_tab = function(ctx, data)
		ctx.state.settings_tab = data.tab
		ctx.ui.need_to_rebuild = true
	end,
	begin_keybind_capture = function(ctx, data)
		if not data or not data.target_action then
			return
		end
		ctx.state.keybind_capture = {
			action = data.target_action,
			pos = data.pos or 1,
		}
	end,
	sub_window_toggle = function(ctx, data)
		if data.window ~= ctx.state.active_window then
			ctx.state.active_window = data.window
			ctx.anim_reg:update("test_animation", "from")
		else
			ctx.state.active_window = nil
			ctx.anim_reg:update("test_animation", "in")
		end
		ctx.ui.need_to_rebuild = true
	end,
	sub_window_open = function(ctx, data)
		print("hasokehu")
		if data.window then
			ctx.state.active_window = data.window
			ctx.anim_reg:update("test_animation", "from")
		else
			ctx.state.active_window = nil
			ctx.anim_reg:update("test_animation", "in")
		end
		ctx.ui.need_to_rebuild = true
	end,

	-- Gameplay
	pause_game = function(ctx)
		local api = ctx.gameplay_api
		if api and api.loaded then
			api:pause()
		end
	end,
	resume_game = function(ctx)
		local api = ctx.gameplay_api
		if api and api.loaded then
			api:play()
		end
	end,
	retry = function(ctx)
		local api = ctx.gameplay_api
		if api and api.loaded then
			api:retry()
		end
	end,
	skip_intro = function(ctx)
		local api = ctx.gameplay_api
		if api and api.loaded and api:canSkipIntro() then
			api:skipIntro()
		end
	end,
	increase_play_speed = function(ctx, action)
		local api = ctx.gameplay_api
		if api and api.loaded then
			local dir = action.dir or 1
			api:increasePlaySpeed(dir)
		end
	end,

	-- Select / chart browser
	toggle_autoplay = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			local replay = api:getReplayBase()
			api:setAutoplay(not replay.autoplay)
		end
	end,
	remove_all_mods = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:removeAllMods()
		end
	end,
	play_preview = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:playPreview()
		end
	end,
	pause_preview = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:pausePreview()
		end
	end,
	toggle_preview = function(ctx)
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
	open_chart_directory = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:openChartDirectory()
		end
	end,
	export_osu_chart = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:exportOsuChart()
		end
	end,
	open_web_notechart = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.selectApi
		if api then
			api:openWebNotechart()
		end
	end,

	-- Locations
	load_locations = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.locationsApi
		if api then
			api:loadLocations()
		end
	end,
	delete_chart_cache = function(ctx)
		local api = SELECT_CONTEXT and SELECT_CONTEXT.locationsApi
		if api then
			api:deleteChartCache()
		end
	end,
	recalculate_scores = function(ctx)
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
		fn(ctx, action)
	end
end

return poll
