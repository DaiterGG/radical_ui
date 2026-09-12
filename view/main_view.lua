---@module
---@author
---@license

local background = require("background")
local icons = require("icons")
local box = require("box")
local button = require("button")
local text = require("text")
local icons = require("icons")
local checkbox = require("checkbox")
local align_mod = require("apply_align")
local spring_list = require("spring_list")
local list_view = require("list_view")
local ui_manager = require("ui_manager")
local ui_element = require("ui_element")
local utils = require("utils")
local profiler = require("profiler")

local Align = align_mod.Align
local Direction = align_mod.Direction
local absolute = align_mod.Absolute
local block = align_mod.Block
local Size = align_mod.Size

local function top_table_row(values, columns, display, text_display, height)
	local row = ui_element({
		display = display,
		widgets = { box() },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ pc_hor = 100, px_vert = height }),
		}),
	})
	local offset = 0
	for _, column in ipairs(columns) do
		local cell = ui_element({
			display = text_display,
			widgets = { text(values[column.key] or "") },
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = offset, y = 0 },
				size = Size({ pc_hor = column.width, pc_vert = 100 }),
			}),
		})
		row:push_child(cell)
		offset = offset + column.width
	end
	return row
end

local function format_number(value, format, fallback)
	if type(value) == "number" then
		return string.format(format, value)
	end
	return value ~= nil and tostring(value) or fallback
end

local function format_accuracy(value)
	if type(value) == "number" then
		return string.format("%.2f%%", value * 100)
	end
	return value ~= nil and tostring(value) or ""
end

local function format_time(value)
	if type(value) == "number" then
		return os.date("%d/%m/%Y", value)
	end
	return value ~= nil and tostring(value) or ""
end

local function difficulty_values(item)
	return {
		dif_name = item.name or item.difficulty_name or item.chartfile_name or "Unnamed difficulty",
		dif_author = item.creator or item.artist or "Unknown creator",
		keymod = tostring(item.inputmode or item.mode or ""),
		dif = format_number(item.osu_diff or item.difficulty, "%.2f", ""),
	}
end

local function score_values(item, index, difficulty)
	return {
		number = tostring(index),
		time = format_time(item.created_at or item.submitted_at),
		accuracy = format_accuracy(item.accuracy),
		difficulty = format_number(difficulty and (difficulty.osu_diff or difficulty.difficulty), "%.2f", ""),
		rating = format_number(item.pp or item.rating, "%.2f", ""),
		rate = format_number(item.rate, "%.2fx", ""),
		score = format_number(item.score, "%.0f", ""),
		misses = format_number(item.misses or item.miss_count, "%.0f", ""),
		mode = tostring(item.inputmode or item.mode or ""),
	}
end

local VIRTUAL_ROW_COUNT = 9

local function add_beatmap_rows(ctx, list, song_h_full, song_h)
	local count = ctx.beatmaps:len()
	if count == 0 then
		return
	end

	local data = ctx.beatmaps.spring_list_data or { scroll_y = 0 }
	local range_count = math.min(VIRTUAL_ROW_COUNT, count)
	local range_start = math.max(1, math.min(data.range_start or 1, count - range_count + 1))
	local range_end = data.range_end and data.range_end >= range_start and math.min(data.range_end, count)
		or range_start + range_count - 1
	profiler.checkpoint("main_view", string.format(
		"[main_view] setup beatmaps range: count=%d range=%d-%d",
		count,
		range_start,
		range_end
	))

	if range_start > 1 then
		list:add_child(ui_element({
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ pc_hor = 100, px_vert = (range_start - 1) * song_h_full }),
			}),
		}))
	end
	profiler.checkpoint("main_view", "setup beatmaps top spacer")

	local beatmap_items = ctx.beatmaps:request_range(range_start, range_end)
	profiler.checkpoint("main_view", "setup beatmaps request range")

	for index = range_start, range_end do
		local beatmap = beatmap_items[index]
		local name = beatmap.title or beatmap.name or beatmap.chartfile_name or "Unnamed beatmap"
		local author = beatmap.artist or beatmap.creator or "Unknown artist"
		local padding = ui_element({
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ pc_hor = 100, px_vert = song_h_full }),
			}),
		})
		local title = ui_element({
			display = "main_list_title",
			widgets = { text(name) },
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 42 },
				size = Size({ pc_hor = 80, px_vert = 42 }),
			}),
		})
		local artist = ui_element({
			display = "main_list_author",
			widgets = { text(author) },
			align = absolute({
				pivot = { x = 50, y = 100 },
				parent_pivot = { x = 50, y = 90 },
				size = Size({ pc_hor = 80, px_vert = 24 }),
			}),
		})
		local content = ui_element({})
		content:push_child(title)
		content:push_child(artist)
		if ctx.beatmaps:is_selected(index) then
			local left_marker = ui_element({
				align = absolute({
					pivot = { x = 0, y = 50 },
					parent_pivot = { x = 0, y = 50 },
					size = Size({ px_hor = song_h, px_vert = song_h }),
				}),
			})
			left_marker:push_child(ui_element({
				display = "main_list_selected",
				widgets = { box() },
				align = absolute({
					pivot = { x = 50, y = 50 },
					parent_pivot = { x = 50, y = 50 },
					size = Size({ px = 24 }),
				}),
			}))
			content:push_child(left_marker)

			local right_marker = ui_element({
				align = absolute({
					pivot = { x = 100, y = 50 },
					parent_pivot = { x = 100, y = 50 },
					size = Size({ px_hor = song_h, px_vert = song_h }),
				}),
			})
			right_marker:push_child(ui_element({
				display = "main_list_selected",
				widgets = { box() },
				align = absolute({
					pivot = { x = 50, y = 50 },
					parent_pivot = { x = 50, y = 50 },
					size = Size({ px = 24 }),
				}),
			}))
			content:push_child(right_marker)
		end
		local list_button = ui_element({
			display = "main_list_button",
			widgets = {
				button(content, {
					on_release = { action = "select_beatmap", index = index },
				}),
			},
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 50 },
				size = Size({ pc_hor = 100, px_vert = song_h }),
			}),
		})

		padding:push_child(list_button)
		list:add_child(padding)

		profiler.checkpoint("main_view", "setup beatmap row")
	end
	profiler.checkpoint("main_view", "setup beatmaps row loop")

	if range_end < count then
		list:add_child(ui_element({
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ pc_hor = 100, px_vert = (count - range_end) * song_h_full }),
			}),
		}))
	end
	profiler.checkpoint("main_view", "setup beatmaps bottom spacer")

	data.item_count = count
	data.range_start = range_start
	data.range_end = range_end

	ctx.beatmaps.spring_list_data = data
	profiler.checkpoint("main_view", "setup beatmaps finalization")
end

return function(ctx)
	local res = ctx.res
	local ratio = ctx.res.w / ctx.res.h

	local header_h = 44

	-- NOTE: SUB MENUS
	-- NOTE: SUB LAYOUT
	local root_window
	if ctx.state.active_window then
		local window_w = 1200
		local window_h = 900
		local footer_h = 90
		local content_h = window_h - footer_h * 2
		local w_header
		local w_main = ui_element({
			display = "w_main",
			widgets = { box() },
			polyline = {
				{ 0, 0 },
				{ window_w - 50, 0 },
				{ window_w, 50 },
				{ window_w, content_h },
				{ 130, content_h },
				{ 0, content_h - 130 },
				{ 0, 0 },
			},
			align = block(Direction.Down, { pc = 100 }),
		})
		if ctx.state.active_window == "Settings" then
			w_header = ui_element({
				widgets = {},
				align = block(Direction.Up, { px = footer_h }),
			})
			local tabs = { "Gameplay", "Menu", "Graphics", "Audio", "Offsets", "Other" }
			-- local tabs_i = { icons.general, icons.graphics, icons.other }
			local tabs_i_left =
				{ icons.gameplay1, icons.select1, icons.graphics1, icons.audio1, icons.offsets1, icons.other1 }
			local tabs_i_right =
				{ icons.gameplay2, icons.select2, icons.graphics2, icons.audio2, icons.offsets2, icons.other2 }
			local active = false
			local tab_h = 60
			local tab_w = 120
			local active_tab_w = 400
			for i, tab in ipairs(tabs) do
				if ctx.state.settings_tab == tab then
					active = true

					local active_tab_t = ui_element({
						display = "w_settings_active_tab_text",
						widgets = { text(tab) },
						align = block(Direction.Left, { pc = 100 }),
					})
					local active_tab = ui_element({
						display = "w_settings_active_tab",
						widgets = { box() },
						polyline = {
							{ 0, footer_h },
							{ footer_h, 0 },
							{ active_tab_w - footer_h, 0 },
							{ active_tab_w, footer_h },
							{ 0, footer_h },
						},
						align = block(Direction.Left, { pc = 100 }),
					})
					local back_button = ui_element({
						widgets = { button(nil, { on_release = { action = "sub_window_open" } }) },
						align = block(Direction.Left, { px = active_tab_w }),
					})

					active_tab:push_child(active_tab_t)
					back_button:push_child(active_tab)
					w_header:push_child(back_button)
				else
					local tab_t = ui_element({
						display = "w_settings_tab_text" .. (active and "_right" or "_left"),
						widgets = { text(active and tabs_i_right[i] or tabs_i_left[i]) },
					})
					local tab_b = ui_element({
						display = "w_settings_tab" .. (active and "_right" or "_left"),
						widgets = { button(tab_t, { on_hield = { action = "settings_tab", tab = tab } }) },
						polyline = active and {
							{ -tab_h, 0 },
							{ -tab_h + tab_w, 0 },
							{ tab_w, tab_h },
							{ 0, tab_h },
							{ -tab_h, 0 },
						} or {
							{ 0, tab_h },
							{ tab_h, 0 },
							{ tab_w + tab_h, 0 },
							{ tab_w, tab_h },
							{ 0, tab_h },
						},
						align = block(Direction.Down, { px = tab_h }),
					})
					local padding = ui_element({
						widgets = { button(nil, { on_release = { action = "sub_window_open" } }) },
						align = block(Direction.Left, { px = tab_w }),
					})
					padding:push_child(tab_b)
					w_header:push_child(padding)
				end
			end
		else
			w_header = ui_element({
				display = "w_header_dis",
				widgets = { box() },
				polyline = {
					{ 0, footer_h },
					{ footer_h, 0 },
					{ footer_h + 300, 0 },
					{ footer_h + 300 + (footer_h - 40), footer_h - 40 },
					{ footer_h + 300 + (footer_h - 40) + 600, footer_h - 40 },
					{ footer_h + 300 + footer_h + 600, footer_h },
					{ 0, footer_h },
				},
				align = block(Direction.Up, { px = footer_h }),
			})
		end
		local w_footer = ui_element({
			display = "w_footer",
			widgets = { box() },
			polyline = {
				{ window_w, 0 },
				{ window_w - footer_h, footer_h },
				{ window_w - footer_h - 500, footer_h },
				{ window_w - footer_h - 500 - (footer_h - 40), 40 },
				{ window_w - footer_h - 500 - (footer_h - 40) - 80, 40 },
				{ window_w - footer_h - 500 - (footer_h - 40) - 80, 40 },
				{ window_w - footer_h - 500 - footer_h - 80, 0 },
				{ window_w, 0 },
			},
			align = block(Direction.Down, { px = footer_h }),
		})
		root_window = ui_element({
			-- display = "header",
			widgets = { button(nil, { on_release = { action = "sub_window_open" } }) },
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 44 / 1080 * 100 },
				size = Size({ pc_hor = 100, px_vert = 1080 - 44 }),
			}),
		})
		local sub_window = ui_element({
			display = "root_window",
			widgets = { button(nil, { on_release = { action = "sub_window_open" } }) },
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 53 },
				size = Size({ px_hor = window_w, px_vert = window_h }),
			}),
		})

		sub_window:push_child(w_header)
		sub_window:push_child(w_footer)
		sub_window:push_child(w_main)
		root_window:push_child(sub_window)
	end
	profiler.checkpoint("main_view", "setup sub window")

	-- NOTE: HEADER
	local header = ui_element({
		display = "header",
		widgets = { box() },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ pc_hor = 100, px_vert = header_h }),
		}),
	})

	local header_back_icon = ui_element({
		display = "header_left_b_icons",
		widgets = { text(icons.back2) },
	})
	local header_button_w = 130
	local header_back = ui_element({
		display = "header_back_b",
		widgets = { button(header_back_icon, { on_release = { action = "quit" } }) },
		polyline = {
			{ 3, 1 },
			{ 120, 1 },
			{ 120, 27 },
			{ 137, header_h },
			{ 1, header_h },
			{ 1, 0 },
		},
		align = block(Direction.Left, { px = header_button_w }),
	})
	header:push_child(header_back)
	local buttons_ic = {
		{ icons.cog1, { action = "sub_window_toggle", window = "Settings" } },
		{ icons.brush1, { action = "sub_window_toggle", window = "Skins" } },
		{ icons.online1, { action = "sub_window_toggle", window = "Online" } },
	}
	for _, b in ipairs(buttons_ic) do
		local header_b_icon = ui_element({
			display = "header_left_b_icons",
			widgets = { text(b[1]) },
		})
		local header_b = ui_element({
			display = "header_left_b",
			widgets = { button(header_b_icon, { on_release = b[2] }) },
			polyline = {
				{ -10, 1 },
				{ 120, 1 },
				{ 120, 27 },
				{ 137, header_h },
				{ 7, header_h },
				{ -10, 27 },
				{ -10, 0 },
			},
			align = block(Direction.Left, { px = header_button_w }),
		})

		header:push_child(header_b)
	end
	profiler.checkpoint("main_view", "setup header")

	-- NOTE: LEFT SIDE
	local nav_h = 122

	local first = ui_element({
		display = "first_b_text",
		widgets = { text("Input") },
	})
	local first_b = ui_element({
		display = "first_b",
		widgets = { button(first) },
		polyline = {
			{ 1, 1 },
			{ 228, 1 },
			{ 228, 54 },
			{ 270, nav_h - 26 },
			{ 270, nav_h },
			{ 1, nav_h },
			{ 1, 0 },
		},
		align = block(Direction.Left, { pc = 33 }),
	})
	local sec = ui_element({
		display = "second_b_text",
		widgets = { text("Play") },
	})
	local second_b = ui_element({
		display = "second_b",
		widgets = { button(sec, { on_release = { action = "start_gameplay" } }) },
		polyline = {
			{ -20, 1 },
			{ 285, 1 },
			{ 285, 30 },
			{ 270, 54 },
			{ 270, nav_h },
			{ 22, nav_h },
			{ 22, nav_h - 26 },
			{ -20, 54 },
			{ -20, 0 },
		},
		align = block(Direction.Left, { pc = 55 }),
	})

	local third = ui_element({
		display = "first_b_text",
		widgets = { text("Mods") },
	})
	local third_b = ui_element({

		display = "third_b",
		widgets = { button(third) },
		polyline = {
			{ 9, 1 },
			{ 200, 1 },
			{ 300, nav_h },
			{ -18, nav_h },
			{ -18, 54 },
			{ 9, 30 },
			{ 9, 1 },
		},
		align = block(Direction.Left, { pc = 100 }),
	})
	local bottom_bp = ui_element({
		widgets = {},
		align = block(Direction.Down, { pc = 12 }),
	})
	bottom_bp:push_child(first_b)
	bottom_bp:push_child(second_b)
	bottom_bp:push_child(third_b)
	-- NOTE: GLASS PANELS
	local panel_w = 700
	local panel_h = 362
	local up_panel = ui_element({
		display = "up_panel",
		widgets = { box() },
		polyline = {
			{ 0, 0 },
			{ panel_w, 0 },
			{ panel_w, panel_h - 98 },
			{ panel_w - 100, panel_h },
			{ 0, panel_h },
			{ 0, 0 },
		},
		align = block(Direction.Up, { pc = 40 }),
	})
	local top_columns = {
		{ key = "number", label = "№", width = 5 },
		-- { key = "player", label = "Player", width = 18 },
		{ key = "time", label = "Time", width = 18 },
		{ key = "accuracy", label = "Accuracy", width = 12 },
		{ key = "difficulty", label = "Difficulty", width = 14 },
		{ key = "rating", label = "Rating", width = 10 },
		{ key = "rate", label = "Rate", width = 10 },
		{ key = "score", label = "Score", width = 10 },
		{ key = "misses", label = "Misses", width = 10 },
		{ key = "mode", label = "Mode", width = 10 },
	}
	local difficulties = ctx.beatmaps:get_difficulties()
	local selected_difficulty_index = ctx.beatmaps:get_selected_difficulty()
	local selected_difficulty = difficulties[selected_difficulty_index] or difficulties[1]
	local scores = ctx.beatmaps:get_scores()
	local top_row_h = 40
	local top_list_h = 320
	local top_header_h = panel_h - top_list_h
	local top_header_values = {}
	for _, column in ipairs(top_columns) do
		top_header_values[column.key] = column.label
	end
	local top_header =
		top_table_row(top_header_values, top_columns, "top_table_header", "top_table_header_text", top_header_h)
	top_header.align = block(Direction.Up, { px = top_header_h })
	local top_list_w = list_view("main_top_list", nil, false)
	local top_row_count = math.ceil(top_list_h / top_row_h)
	for index = 1, top_row_count do
		local values = scores[index] and score_values(scores[index], index, selected_difficulty) or {}
		top_list_w:add_child(
			top_table_row(
				values,
				top_columns,
				index % 2 == 1 and "top_table_row_dark" or "top_table_row_transparent",
				"top_table_cell_text",
				top_row_h
			)
		)
	end
	local top_list = ui_element({
		display = "top_list",
		widgets = { top_list_w },
		align = block(Direction.Down, { pc = 100 }),
	})
	local top_table = ui_element({
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ px_hor = panel_w - 100, pc_vert = 100 }),
		}),
	})
	top_table:push_child(top_header)
	top_table:push_child(top_list)
	up_panel:push_child(top_table)
	local middle_w = 580
	local middle_h = 272
	local middle_panel = ui_element({
		display = "middle_panel",
		widgets = { box() },
		polyline = {
			{ 0, 0 },
			{ middle_w, 0 },
			{ middle_w, 130 },
			{ middle_w - 40, 170 },
			{ middle_w - 40, middle_h },
			{ 0, middle_h },
			{ 0, 0 },
		},
		align = block(Direction.Up, { pc = 50 }),
	})
	local down_w = 620
	local down_h = 280
	local down_panel = ui_element({
		display = "down_panel",
		widgets = { box() },
		polyline = {
			{ 0, 0 },
			{ down_w - 80, 0 },
			{ down_w - 40, 40 },
			{ down_w - 40, 100 },
			{ down_w, 140 },
			{ down_w, down_h },
			{ 0, down_h },
			{ 0, 0 },
		},
		align = block(Direction.Up, { pc = 100 }),
	})
	local down_list_scrollbar = ui_element({
		display = "down_list_scrollbar",
		widgets = { box() },
	})
	local down_list_w = list_view("main_down_list", down_list_scrollbar, true)
	local down_row_h = 56
	for index, difficulty in ipairs(difficulties) do
		local item = difficulty_values(difficulty)
		local content = ui_element({
			display = index % 2 == 1 and "down_list_item_dark" or "down_list_item_transparent",
			widgets = { box() },
		})
		local row = ui_element({
			widgets = {
				button(content, {
					on_press = { action = "select_difficulty", index = index },
					on_hield = { action = "select_difficulty", index = index },
				}),
			},
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ pc_hor = 100, px_vert = down_row_h }),
			}),
		})
		if ctx.state.dif_selected == index then
			content:push_child(ui_element({
				display = "down_list_item_selected",
				widgets = { box() },
				align = absolute({
					pivot = { x = 50, y = 50 },
					parent_pivot = { x = 5, y = 50 },
					size = Size({ px = 30 }),
				}),
			}))
		end
		content:push_child(ui_element({
			display = "down_list_item_name",
			widgets = { text(item.dif_name) },
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 10, y = 0 },
				size = Size({ pc_hor = 58, pc_vert = 50 }),
			}),
		}))
		content:push_child(ui_element({
			display = "down_list_item_author",
			widgets = { text(item.dif_author) },
			align = absolute({
				pivot = { x = 0, y = 100 },
				parent_pivot = { x = 10, y = 100 },
				size = Size({ pc_hor = 58, pc_vert = 50 }),
			}),
		}))
		content:push_child(ui_element({
			display = "down_list_item_keymod",
			widgets = { text(item.keymod) },
			align = absolute({
				pivot = { x = 50, y = 0 },
				parent_pivot = { x = 90, y = 0 },
				size = Size({ pc_hor = 24, pc_vert = 50 }),
			}),
		}))
		content:push_child(ui_element({
			display = "down_list_item_dif",
			widgets = { text(item.dif) },
			align = absolute({
				pivot = { x = 50, y = 100 },
				parent_pivot = { x = 90, y = 100 },
				size = Size({ pc_hor = 24, pc_vert = 50 }),
			}),
		}))
		down_list_w:add_child(row)
	end
	local down_list = ui_element({
		display = "down_list",
		widgets = { down_list_w },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ px_hor = middle_w - 40, pc_vert = 100 }),
		}),
	})
	down_panel:push_child(down_list)
	profiler.checkpoint("main_view", "setup left side")

	-- NOTE: RIGHT SIDE
	local right_width = 638
	local right_scroll_gap = 40

	-- NOTE: RIGHT HEADER
	local right_header_h = 88
	local first_header_w = 200
	local third_header_w = first_header_w
	local header_overlap = 71
	local second_header_w = right_width - first_header_w - third_header_w
	local header_corner = 34
	local header_notch = 25
	local header_bottom_inset = 40
	local first_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.collections1) },
	})
	local first_header_b = ui_element({
		display = "first_header_b",
		widgets = { button(first_header) },
		polyline = {
			{ 0, 0 },
			{ first_header_w + header_overlap, 0 },
			{ first_header_w - header_corner + header_overlap, header_corner },
			{ first_header_w - header_corner - header_notch + header_overlap, header_corner },
			{ first_header_w - right_header_h - header_notch + header_overlap, right_header_h },
			{ header_bottom_inset, right_header_h },
			{ 0, right_header_h - header_bottom_inset },
			{ 0, 0 },
		},
		align = block(Direction.Right, { px = first_header_w }),
	})

	local second_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.sort1) },
	})
	local second_header_b = ui_element({
		display = "second_header_b",
		widgets = { button(second_header) },
		polyline = {
			{ header_overlap, -1 },
			{ 2 + second_header_w - header_overlap, 0 },
			{ 2 + second_header_w - header_overlap + header_corner, header_corner - 1 },
			{ 2 + second_header_w - header_overlap + header_corner + header_notch, header_corner - 1 },
			{ 2 + second_header_w - header_overlap + right_header_h + header_notch, right_header_h },
			{ -2 + header_overlap - right_header_h - header_notch, right_header_h },
			{ -2 + header_overlap - header_corner - header_notch, header_corner - 1 },
			{ -2 + header_overlap - header_corner, header_corner - 1 },
			{ -2 + header_overlap, -1 },
		},
		align = block(Direction.Right, { px = second_header_w }),
	})

	local third_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.filter1) },
	})
	local third_header_b = ui_element({
		display = "first_header_b",
		widgets = { button(third_header) },
		polyline = {
			{ -header_overlap, 0 },
			{ third_header_w, 0 },
			{ third_header_w, right_header_h - header_bottom_inset },
			{ third_header_w - header_bottom_inset, right_header_h },
			{ -header_overlap + right_header_h + header_notch, right_header_h },
			{ -header_overlap + header_corner + header_notch, header_corner },
			{ -header_overlap + header_corner, header_corner },
			{ -header_overlap, 0 },
		},
		align = block(Direction.Right, { px = third_header_w }),
	})

	local up_header = ui_element({
		widgets = {},
		align = block(Direction.Up, { px = right_header_h }),
	})
	up_header:push_child(third_header_b)
	up_header:push_child(second_header_b)
	up_header:push_child(first_header_b)

	-- NOTE: RIGHT SCROLL
	local scroll_h = 1080 - header_h - right_header_h * 2
	local song_h_full = scroll_h / 7
	local song_h = song_h_full - 10

	local main_list_w = spring_list()

	profiler.checkpoint("main_view", "setup right_header")
	add_beatmap_rows(ctx, main_list_w, song_h_full, song_h)
	profiler.checkpoint("main_view", "setup scroll_total")

	local main_list = ui_element({
		display = "main_list",
		widgets = { main_list_w },

		align = absolute({
			pivot = { x = 50, y = 50 },
			parent_pivot = { x = 50, y = 50 },
			size = Size({ px_hor = right_width - (right_scroll_gap * 2), px_vert = scroll_h }),
		}),
	})
	-- NOTE: RIGHT FOOTTER

	local first_footer = ui_element({
		display = "right_footer_text",
		widgets = { text("Locations") },
	})
	local first_footer_b = ui_element({
		display = "first_header_b",
		widgets = { button(first_footer) },
		polyline = {
			{ 0, right_header_h },
			{ first_header_w + header_overlap, right_header_h },
			{ first_header_w - header_corner + header_overlap, right_header_h - header_corner },
			{
				first_header_w - header_corner - header_notch + header_overlap,
				right_header_h - header_corner,
			},
			{
				first_header_w - right_header_h - header_notch + header_overlap,
				0,
			},
			{ header_bottom_inset, 0 },
			{ 0, header_bottom_inset },
			{ 0, right_header_h },
		},
		align = block(Direction.Right, { px = first_header_w }),
	})

	local second_footer = ui_element({
		display = "right_footer_text",
		widgets = { text("Collections") },
	})
	local second_footer_b = ui_element({
		display = "second_header_b",
		widgets = { button(second_footer) },
		polyline = {
			{ -2 + header_overlap - right_header_h - header_notch, 0 },
			{ 2 + second_header_w - header_overlap + right_header_h + header_notch, 0 },
			{
				2 + second_header_w - header_overlap + right_header_h + header_notch - (right_header_h - header_corner),
				right_header_h - header_corner + 1,
			},
			{
				2 + second_header_w - header_overlap + header_corner,
				right_header_h - header_corner + 1,
			},
			{
				2 + second_header_w - header_overlap,
				right_header_h,
			},
			{
				-2 + header_overlap,
				right_header_h,
			},
			{ -2 + header_overlap - header_corner, right_header_h - header_corner + 1 },
			{ -2 + header_overlap - header_corner - header_notch, right_header_h - header_corner + 1 },
			{ -2 + header_overlap - right_header_h - header_notch, 0 },
		},
		align = block(Direction.Right, { px = second_header_w }),
	})

	local third_footer = ui_element({
		display = "right_footer_text",
		widgets = { text("Direct") },
	})
	local third_footer_b = ui_element({
		display = "first_header_b",
		widgets = { button(third_footer) },
		polyline = {
			{ -header_overlap, right_header_h },
			{ third_header_w, right_header_h },
			{ third_header_w, header_bottom_inset },
			{ third_header_w - header_bottom_inset, 0 },
			{ -header_overlap + right_header_h + header_notch, 0 },
			{
				-header_overlap + header_corner + header_notch,
				right_header_h - header_corner,
			},
			{ -header_overlap + header_corner, right_header_h - header_corner },
			{ -header_overlap, right_header_h },
		},
		align = block(Direction.Right, { px = third_header_w }),
	})

	local down_footer = ui_element({
		widgets = {},
		align = block(Direction.Down, { px = right_header_h }),
	})
	down_footer:push_child(third_footer_b)
	down_footer:push_child(second_footer_b)
	down_footer:push_child(first_footer_b)
	profiler.checkpoint("main_view", "setup footer")

	-- NOTE: MAIN LAYOUT
	local left_width = 750
	local main_anim_length = 300
	local left_p = ui_element({
		widgets = {},
		align = absolute({
			pivot = { x = 0, y = 50 },
			parent_pivot = { x = 0, y = 50 },
			size = Size({ px_hor = left_width, pc_vert = 100 }),
		}):animation({
			key = "test_animation",
			delta_pos = { x = -left_width + 40, y = 0 },
			ease_fn = "out",
			length_ms = main_anim_length,
		}),
	})
	left_p:push_child(bottom_bp)
	left_p:push_child(up_panel)
	left_p:push_child(middle_panel)
	left_p:push_child(down_panel)

	local right_p = ui_element({
		widgets = {},
		align = absolute({
			pivot = { x = 100, y = 50 },
			parent_pivot = { x = 100, y = 50 },
			size = Size({ px_hor = right_width, pc_vert = 100 }),
		}):animation({
			key = "test_animation",
			delta_pos = { x = right_width - 70, y = 0 },
			ease_fn = "out",
			length_ms = main_anim_length,
		}),
	})
	right_p:push_child(main_list)
	right_p:push_child(up_header)
	right_p:push_child(down_footer)

	local root = ui_element({
		display = "root",
		widgets = { box() },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ pc_hor = 100, pc_vert = 100 }),
		}),
	})
	local padding = ui_element({
		align = block(Direction.Up, { px = header_h }),
	})
	root:push_child(padding)
	if ratio > 1.2527 then
		root:push_child(left_p)
		root:push_child(right_p)
	else
		right_p.align = absolute({
			pivot = { x = 50, y = 50 },
			parent_pivot = { x = 50, y = 50 },
			size = Size({ px_hor = right_width, pc_vert = 100 }),
		})
		root:push_child(right_p)
	end

	-- local test_p = ui_element({
	-- 	display = "test_p",
	-- 	widgets = { button(first) },
	-- 	polyline = {
	-- 		{ x_px = 0, y_pc = 0 },
	-- 		{ x_px = 220, y_pc = 0 },
	-- 		{ x_px = 220, y_pc = 45 },
	-- 		{ x_px = 320, y_pc = 100 },
	-- 		{ x_pc = 0, y_pc = 100, center = false },
	-- 		{ x_px = 0, y_px = 0, center = false },
	-- 	},
	-- 	align = absolute({
	-- 		pivot = { x = 0, y = 100 },
	-- 		parent_pivot = { x = 0, y = 100 },
	-- 		size = Size({ pc_hor = 20, pc_vert = 10 }),
	-- 	}),
	-- })
	-- root:push_child(test_p)

	-- local bar = ui_element({ display = "scrollable_list_scroll_bar", widgets = { box() } })
	-- local ch = ui_element({ display = "header", widgets = { box() }, align = block(Direction.Up, "50") })
	-- bar:push_child(ch)
	-- local lv = spring_list()

	-- for _, title in ipairs(songs) do
	-- 	local txt = ui_element({ display = "main_text", widgets = { text(title) } })
	-- 	local item = ui_element({
	-- 		display = "list_item",
	-- 		widgets = { button( txt) },
	-- 		align = absolute({
	-- 			pivot = { x = 0, y = 0 },
	-- 			parent_pivot = { x = 0, y = 0 },
	-- 			size = Size({ pc_hor = 100, px_vert = item_height }),
	-- 		}),
	-- 	})
	-- 	lv:add_child(item)
	-- end
	-- local padding = ui_element({
	-- 	display = "header",
	-- 	widgets = { box(), text("Locations Manage Collections Direct") },
	-- 	align = block(Direction.Down, "60"),
	-- })
	-- root:push_child(padding)

	-- local list_elem = ui_element({ display = "scrollable_list", widgets = { lv }, align = block(Direction.Left, "40") })

	-- root:push_child(list_elem)
	-- local check = ui_element({
	-- 	display = "checkbox",
	-- 	widgets = { checkbox(nil, false, ui_element({ display = "main_text", widgets = { text("hi") } })) },
	-- 	align = absolute({
	-- 		pivot = { x = 0, y = 0 },
	-- 		parent_pivot = { x = 0, y = 0 },
	-- 		size = Size({ px_hor = 150, px_vert = 150 }),
	-- 	}),
	-- })

	-- utils.print(root)

	ctx.ui.root_elements = {}
	if root then
		ctx.ui.root_elements[#ctx.ui.root_elements + 1] = root
	end
	if root_window then
		ctx.ui.root_elements[#ctx.ui.root_elements + 1] = root_window
	end
	if header then
		ctx.ui.root_elements[#ctx.ui.root_elements + 1] = header
	end

	ctx.ui.need_to_realign = true
	profiler.checkpoint("main_view", "setup main layout and finalization")
end
