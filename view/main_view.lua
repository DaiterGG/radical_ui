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
local ui_manager = require("ui_manager")
local ui_element = require("ui_element")
local utils = require("utils")

local Align = align_mod.Align
local Direction = align_mod.Direction
local absolute = align_mod.Absolute
local block = align_mod.Block
local Size = align_mod.Size

local function add_beatmap_rows(ctx, list, song_h_full, song_h)
	local count = ctx.beatmaps:len()
	if count == 0 then
		return
	end

	local beatmap_items = ctx.beatmaps:request_range(1, count)

	for _, beatmap in ipairs(beatmap_items) do
		local name = beatmap.title or beatmap.name or beatmap.chartfile_name or "Unnamed beatmap"
		local author = beatmap.artist or beatmap.creator or "Unknown artist"
		local padding = ui_element({
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ per_hor = 100, px_vert = song_h_full }),
			}),
		})
		local title = ui_element({
			display = "main_list_title",
			widgets = { text(name) },
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 42 },
				size = Size({ per_hor = 80, px_vert = 42 }),
			}),
		})
		local artist = ui_element({
			display = "main_list_author",
			widgets = { text(author) },
			align = absolute({
				pivot = { x = 50, y = 100 },
				parent_pivot = { x = 50, y = 90 },
				size = Size({ per_hor = 80, px_vert = 24 }),
			}),
		})
		local content = ui_element({})
		content:push_child(title)
		content:push_child(artist)
		local list_button = ui_element({
			display = "main_list_button",
			widgets = { button(content) },
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 50 },
				size = Size({ per_hor = 100, px_vert = song_h }),
			}),
		})

		padding:push_child(list_button)
		list:add_child(padding)
	end
end

return function(ctx)
	if not ctx.ui.need_to_rebuild then
		return
	end
	ctx.ui.need_to_rebuild = false

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
				size = Size({ per_hor = 100, px_vert = 1080 - 44 }),
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

	-- NOTE: HEADER
	local header = ui_element({
		display = "header",
		widgets = { box() },
		align = block(Direction.Up, { px = header_h }),
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
		widgets = { button(sec) },
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
	local down_h = 273
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
	local song_h_full = (1080 - header_h - right_header_h * 2) / 7
	local song_h = song_h_full - 10

	local main_list_w = spring_list()
	add_beatmap_rows(ctx, main_list_w, song_h_full, song_h)

	local main_list = ui_element({
		display = "main_list",
		widgets = { main_list_w },
		align = block(Direction.Left, { px = right_width - (right_scroll_gap * 2) }),
	})
	local middle_scroll = ui_element({
		widgets = {},
		align = block(Direction.Right, { px = right_width - right_scroll_gap }),
	})
	middle_scroll:push_child(main_list)
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
	-- NOTE: MAIN LAYOUT
	local left_width = 750
	local main_anim_length = 300
	local left_p = ui_element({
		widgets = {},
		align = absolute({
			pivot = { x = 0, y = 50 },
			parent_pivot = { x = 0, y = 50 },
			size = Size({ px_hor = left_width, per_vert = 100 }),
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
			size = Size({ px_hor = right_width, per_vert = 100 }),
		}):animation({
			key = "test_animation",
			delta_pos = { x = right_width - 70, y = 0 },
			ease_fn = "out",
			length_ms = main_anim_length,
		}),
	})
	right_p:push_child(up_header)
	right_p:push_child(down_footer)
	right_p:push_child(middle_scroll)

	local root = ui_element({
		display = "root",
		widgets = { box() },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ per_hor = 100, per_vert = 100 }),
		}),
	})
	root:push_child(header)
	if ratio > 1.2527 then
		root:push_child(left_p)
		root:push_child(right_p)
	else
		right_p.align = absolute({
			pivot = { x = 50, y = 50 },
			parent_pivot = { x = 50, y = 50 },
			size = Size({ px_hor = right_width, per_vert = 100 }),
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
	-- 		size = Size({ per_hor = 20, per_vert = 10 }),
	-- 	}),
	-- })
	-- root:push_child(test_p)

	-- local bar = ui_element({ display = "scrollable_list_scroll_bar", widgets = { box() } })
	-- local ch = ui_element({ display = "header", widgets = { box() }, align = block(Direction.Up, "50") })
	-- bar:push_child(ch)
	-- local lv = spring_list()

	-- local item_height = 48
	-- for _, title in ipairs(songs) do
	-- 	local txt = ui_element({ display = "main_text", widgets = { text(title) } })
	-- 	local item = ui_element({
	-- 		display = "list_item",
	-- 		widgets = { button( txt) },
	-- 		align = absolute({
	-- 			pivot = { x = 0, y = 0 },
	-- 			parent_pivot = { x = 0, y = 0 },
	-- 			size = Size({ per_hor = 100, px_vert = item_height }),
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

	ctx.ui.need_to_realign = true
end
