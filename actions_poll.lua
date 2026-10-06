local profiler = require("profiler")
local utils = require("utils")
local text_input = require("text_input")
local execute

local function reset_input_list_scroll(ctx)
	local data = ctx.widget_reg:get("input_menu") or {}
	data.y_scroll = -1
	ctx.widget_reg:set("input_menu", data)
end

execute = {
	default_input = function(ctx, data)
		local key = ctx.input_state.input_key
		local new_input = data.new_input
		local after = data.after

		if new_input then
			text_input:insert_text(ctx, key, new_input)
		else
			text_input:set_text(ctx, key, after)
		end
	end,
	keyinput = function(ctx, data)
		local input_key = ctx.input_state.input_key
		text_input:trigger_input(ctx, input_key, { new_input = data.keypress })
	end,
	keybind_capture = function(ctx, data)
		ctx.input_state.keybind_capture = data.rebind
		ctx.state.need_to_rebuild = true
	end,
	debug_rebuild = function(ctx, _)
		ctx.state.need_to_rebuild = true
	end,
	input_left = function(ctx, action)
		local input_key = ctx.input_state.input_key
		text_input:move_caret(ctx, input_key, -1, action.modifiers)
	end,
	input_right = function(ctx, action)
		local input_key = ctx.input_state.input_key
		text_input:move_caret(ctx, input_key, 1, action.modifiers)
	end,
	input_home = function(ctx)
		local input_key = ctx.input_state.input_key
		text_input:move_caret(ctx, input_key, 1 - ctx.widget_reg:get(input_key).caret)
	end,
	input_end = function(ctx)
		local input_key = ctx.input_state.input_key
		local data = ctx.widget_reg:get(input_key)
		text_input:move_caret(ctx, input_key, #data.input_field + 1 - data.caret)
	end,
	input_backspace = function(ctx, action)
		local input_key = ctx.input_state.input_key
		text_input:erase(ctx, input_key, true, action.modifiers and action.modifiers.ctrl)
	end,
	input_delete = function(ctx, action)
		local input_key = ctx.input_state.input_key
		text_input:erase(ctx, input_key, false, action.modifiers and action.modifiers.ctrl)
	end,
	input_select_all = function(ctx)
		local input_key = ctx.input_state.input_key
		text_input:select_all(ctx, input_key)
	end,
	input_deselect = function(ctx)
		ctx.input_state.input_key = nil
	end,
	input_copy = function(ctx)
		local input_key = ctx.input_state.input_key
		love.system.setClipboardText(text_input:selected_text(ctx, input_key))
	end,
	input_cut = function(ctx)
		local input_key = ctx.input_state.input_key
		local selected = text_input:selected_text(ctx, input_key)
		if selected ~= "" then
			love.system.setClipboardText(selected)
			text_input:erase(ctx, input_key, false, false)
		end
	end,
	input_paste = function(ctx)
		local input_key = ctx.input_state.input_key
		text_input:insert_text(ctx, input_key, love.system.getClipboardText() or "")
	end,
	quit = function(ctx)
		if ctx.state.scene == "gameplay" then
			execute.stop_gameplay(ctx)
			return
		end
		love.event.push("quit") -- same as the osu_ui example: the loop polls it and exits
	end,
	select_beatmap = function(ctx, data)
		if ctx.state.active_window then
			return
		end

		if ctx.beatmaps.selected_index == data.index then
			return
		end

		ctx.beatmaps:select(data.index)
		ctx.state.dif_selected = ctx.beatmaps:select_middle_difficulty() or 1
		local spring_list_data = ctx.beatmaps.spring_list_data or {}
		spring_list_data.scroll_to = data.index
		ctx.beatmaps.spring_list_data = spring_list_data
		local list_data = ctx.widget_reg:get("main_down_list")

		if list_data then
			local difficulty_count = #ctx.beatmaps:get_difficulties()
			local content_height = difficulty_count * list_data.child_height
			local max_scroll = math.max(0, content_height - list_data.viewport_height)
			local selected_offset = (ctx.state.dif_selected - 1) * list_data.child_height
			local centered_scroll = selected_offset - (list_data.viewport_height - list_data.child_height) / 2
			list_data.scroll_y = math.max(0, math.min(centered_scroll, max_scroll))
			list_data.spring_velocity = 0
			list_data.springing = false
		end

		ctx.beatmaps:play_preview()
		ctx.state.need_to_rebuild = true
	end,
	start_gameplay = function(ctx)
		if ctx.state.scene ~= "select" then
			return
		end

		ctx.beatmaps:ensure_loaded()
		if not ctx.game.selectModel:notechartExists() then
			return
		end

		ctx.beatmaps:stop_preview()
		ctx.gameplay_api:start()
		ctx.state.scene = "gameplay"
		ctx.state.need_to_rebuild = true
	end,
	stop_gameplay = function(ctx)
		if ctx.state.scene ~= "gameplay" then
			return
		end

		ctx.gameplay_api:stop()
		ctx.state.scene = "select"
		ctx.beatmaps:reselect(ctx.beatmaps.selected_index, ctx.state.dif_selected)
		ctx.beatmaps:play_preview()
		ctx.state.need_to_rebuild = true
		ctx.state.need_to_realign = true
	end,
	ui_scale_custom = function(ctx, new_scale)
		ctx.settings.ui_settings.custom_scale = new_scale.attached
		ctx.state.need_to_rebuild = true
		ctx.state.ui_scale = ctx.settings.ui_settings.custom_scale * ctx.state.res.h / 1080
	end,
	ui_scale_custom_reset = function(ctx, data)
		ctx.settings.ui_settings.custom_scale = data.value
		ctx.state.need_to_rebuild = true
		ctx.state.ui_scale = ctx.settings.ui_settings.custom_scale * ctx.state.res.h / 1080
	end,
	main_list_up = function(ctx)
		if ctx.state.active_window == "Input" then
			ctx.input_model.input_pos = math.max(1, ctx.input_model.input_pos - 1)
			ctx.state.need_to_rebuild = true
			return
		end
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		local count = ctx.beatmaps:len()
		if count == 0 then
			return
		end
		local current_index = ctx.beatmaps.selected_index or 1
		local next_index = math.max(1, math.min(current_index - 1, count))

		execute.select_beatmap(ctx, { index = next_index })
	end,
	main_list_down = function(ctx)
		if ctx.state.active_window == "Input" then
			ctx.input_model.input_pos = math.min(#ctx.input_model.all_standard, ctx.input_model.input_pos + 1)
			ctx.state.need_to_rebuild = true
			return
		end
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		local count = ctx.beatmaps:len()
		if count == 0 then
			return
		end
		local current_index = ctx.beatmaps.selected_index or 1
		local next_index = math.max(1, math.min(current_index + 1, count))

		execute.select_beatmap(ctx, { index = next_index })
	end,
	main_list_page_up = function(ctx)
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		local count = ctx.beatmaps:len()
		if count == 0 then
			return
		end
		local current_index = ctx.beatmaps.selected_index or 1
		local next_index = math.max(1, math.min(current_index - 7, count))

		execute.select_beatmap(ctx, { index = next_index })
	end,
	main_list_page_down = function(ctx)
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		local count = ctx.beatmaps:len()
		if count == 0 then
			return
		end
		local current_index = ctx.beatmaps.selected_index or 1
		local next_index = math.max(1, math.min(current_index + 7, count))

		execute.select_beatmap(ctx, { index = next_index })
	end,
	main_list_first = function(ctx)
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		if ctx.beatmaps:len() == 0 then
			return
		end

		execute.select_beatmap(ctx, { index = 1 })
	end,
	main_list_last = function(ctx)
		if ctx.state.active_window then
			return
		end

		ctx.beatmaps:ensure_loaded()
		local count = ctx.beatmaps:len()
		if count == 0 then
			return
		end

		execute.select_beatmap(ctx, { index = count })
	end,
	settings_tab = function(ctx, data)
		ctx.state.settings_tab = data.tab
		ctx.state.need_to_rebuild = true
	end,
	input_pos_up = function(ctx)
		ctx.input_model.input_pos = math.max(1, ctx.input_model.input_pos - 1)
		ctx.state.need_to_rebuild = true
	end,
	input_pos_down = function(ctx)
		ctx.input_model.input_pos = math.min(#ctx.input_model.all_standard, ctx.input_model.input_pos + 1)
		ctx.state.need_to_rebuild = true
	end,
	set_play_speed = function(ctx, data)
		ctx.game.speedModel:set(data.attached)
	end,
	set_speed_type = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.speedType = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_action_type = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.tempoFactor = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_action_on_fail = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.actionOnFail = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_scale_scroll_speed = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.scaleSpeed = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_long_note_shortening = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.longNoteShortening = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_long_note_shortening_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.longNoteShortening = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_auto_key_sound = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.autoKeySound = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_auto_key_sound_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.autoKeySound = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_event_based_render = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.eventBasedRender = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_event_based_render_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.eventBasedRender = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_prepare_time = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.prepare = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_prepare_time_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.prepare = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_play_pause_time = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.playPause = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_play_pause_time_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.playPause = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_pause_play_time = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.pausePlay = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_pause_play_time_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.pausePlay = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_play_retry_time = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.playRetry = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_play_retry_time_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.playRetry = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_pause_retry_time = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.pauseRetry = data.attached
		ctx.state.need_to_rebuild = true
	end,
	set_pause_retry_time_reset = function(ctx, data)
		ctx.game.configModel.configs.settings.gameplay.time.pauseRetry = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_blur = function(ctx, data)
		ctx.settings.ui_settings.blur = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_blur_reset = function(ctx, data)
		ctx.settings.ui_settings.blur = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_background = function(ctx, data)
		ctx.settings.ui_settings.background = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_background_reset = function(ctx, data)
		ctx.settings.ui_settings.background = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_hot_reload = function(ctx, data)
		ctx.settings.ui_settings.hot_reload = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_hot_reload_reset = function(ctx, data)
		ctx.settings.ui_settings.hot_reload = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_animations = function(ctx, data)
		ctx.settings.ui_settings.animations = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_animations_reset = function(ctx, data)
		ctx.settings.ui_settings.animations = data.value
		ctx.state.need_to_rebuild = true
	end,
	set_theme = function(ctx, data)
		ctx.game_api:setTheme(data.value)
		ctx.state.need_to_rebuild = true
	end,
	reload_ui = function(ctx)
		local theme_id = "radical_ui"
		local themes = ctx.game_api:getThemes()
		for _, theme in ipairs(themes) do
			if theme.id == theme_id and theme.name == "Radical UI" then
				ctx.game_api:setTheme(theme_id)
				ctx.state.need_to_rebuild = true
				return
			end
		end
		error("Unknown UI theme: Radical UI")
	end,
	set_dummy_value = function(ctx, data)
		local key = ctx.input_state.input_key
		if data.button_value then
			ctx.state.need_to_rebuild = true
			ctx.settings.ui_settings.dummy_value = ctx.settings.ui_settings.dummy_value + data.button_value
			return
		end
		local new_input = data.new_input
		local after = data.after

		if new_input then
			if not tonumber(new_input) then
				return
			end
			local new_value = text_input:insert_text(ctx, key, new_input)
			ctx.settings.ui_settings.dummy_value = tonumber(new_value)
		else
			text_input:set_text(ctx, key, after)
			ctx.settings.ui_settings.dummy_value = tonumber(after)
		end
	end,
	trigger_animation = function(ctx, data)
		if not data or not data.key then
			error("trigger_animation requires key, direction, and force")
		end
		ctx.anim_reg:update(data.key, data.direction, data.forced)
	end,
	sub_window_toggle = function(ctx, data)
		if data.window ~= ctx.state.active_window then
			ctx.state.active_window = data.window
			if data.window == "Input" then
				reset_input_list_scroll(ctx)
			end
			ctx.anim_reg:update("test_animation", "from")
		else
			ctx.state.active_window = nil
			ctx.anim_reg:update("test_animation", "in")
		end
		ctx.state.need_to_rebuild = true
	end,
	sub_window_open = function(ctx, data)
		if data.window then
			ctx.state.active_window = data.window
			if data.window == "Input" then
				reset_input_list_scroll(ctx)
			end
			ctx.anim_reg:update("test_animation", "from")
		else
			ctx.state.active_window = nil
			ctx.anim_reg:update("test_animation", "in")
		end
		ctx.state.need_to_rebuild = true
	end,
	select_difficulty = function(ctx, data)
		if ctx.state.dif_selected ~= data.index then
			ctx.beatmaps:select_difficulty(data.index)
			ctx.beatmaps:play_preview()
			ctx.state.dif_selected = data.index
			ctx.state.need_to_rebuild = true
		end
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
}

local function poll(ctx)
	while true do
		local action = ctx.action_queue:pop()
		if not action then
			return
		end
		local fn = execute[action.action]
		if fn then
			fn(ctx, action)
		end
	end
end

return poll
