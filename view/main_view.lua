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
local list_view = require("list_view")
local ui_manager = require("ui_manager")
local ui_element = require("ui_element")
local utils = require("utils")

local Align = align_mod.Align
local Direction = align_mod.Direction
local absolute = align_mod.Absolute
local block = align_mod.Block
local Size = align_mod.Size

return function(ctx)
	if not ctx.ui.need_to_rebuild then
		return
	end
	ctx.ui.need_to_rebuild = false

	local res = ctx.res
	local ratio = ctx.res.w / ctx.res.h

	-- NOTE: SUB MENUS
	-- NOTE: SUB LAYOUT
	local root_window
	if ctx.state.active_window then
		local w_header
		local w_main = ui_element({
			display = "w_main",
			widgets = { box() },
			align = block(Direction.Down, { pc = 100 }),
		})
		if ctx.state.active_window == "Settings" then
			w_header = ui_element({
				widgets = {},
				align = block(Direction.Up, { px = 90 }),
			})
			local tabs = { "General", "Graphics", "Other", "BBBB", "AAAA" }
			-- local tabs_i = { icons.general, icons.graphics, icons.other }
			local tabs_i_left = { icons.back2, icons.cog1, icons.input1, icons.input1, icons.input1 }
			local tabs_i_right = { icons.back2, icons.cog1, icons.input1, icons.input1, icons.input1 }
			local active = false
			for i, tab in pairs(tabs) do
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
						align = block(Direction.Left, { px = 400 }),
					})

					active_tab:push_child(active_tab_t)
					w_header:push_child(active_tab)
				else
					local tab_t = ui_element({
						display = "w_settings_tab_text",
						widgets = { text(active and tabs_i_right[i] or tabs_i_left[i]) },
					})
					local tab_b = ui_element({
						display = "w_settings_tab" .. (active and "_right" or "_left"),
						widgets = { button({ action = "settings_tab", tab = tab }, tab_t) },
						align = block(Direction.Down, { px = 60 }),
					})
					local padding = ui_element({
						align = block(Direction.Left, { px = 120 }),
					})
					padding:push_child(tab_b)
					w_header:push_child(padding)
				end
			end
		else
			w_header = ui_element({
				display = "w_header_dis",
				widgets = { box() },
				align = block(Direction.Up, { px = 90 }),
			})
		end
		local w_footer = ui_element({
			display = "w_footer",
			widgets = { box() },
			align = block(Direction.Down, { px = 90 }),
		})
		root_window = ui_element({
			display = "root_window",
			widgets = {},
			align = absolute({
				pivot = { x = 50, y = 50 },
				parent_pivot = { x = 50, y = 53 },
				size = Size({ px_hor = 1200, px_vert = 900 }),
			}),
		})

		root_window:push_child(w_header)
		root_window:push_child(w_footer)
		root_window:push_child(w_main)
	end

	-- NOTE: HEADER
	local header = ui_element({
		display = "header",
		widgets = { box() },
		align = block(Direction.Up, { px = 44 }),
	})

	local header_back_icon = ui_element({
		display = "header_left_b_icons",
		widgets = { text(icons.back2) },
	})
	local header_back = ui_element({
		display = "header_back_b",
		widgets = { button("quit", header_back_icon) },
		align = block(Direction.Left, { px = 130 }),
	})
	header:push_child(header_back)
	local buttons_ic =
		{ { icons.cog1, "quit" }, { icons.input1, "quit" }, { icons.brush1, "quit" }, { icons.online1, "quit" } }
	for _, b in pairs(buttons_ic) do
		local header_b_icon = ui_element({
			display = "header_left_b_icons",
			widgets = { text(b[1]) },
		})
		local header_b = ui_element({
			display = "header_left_b",
			widgets = { button(b[2], header_b_icon) },
			align = block(Direction.Left, { px = 130 }),
		})

		header:push_child(header_b)
	end
	-- NOTE: LEFT SIDE

	local first = ui_element({
		display = "first_b_text",
		widgets = { text("Input") },
	})
	local first_b = ui_element({
		display = "first_b",
		widgets = { button(nil, first) },
		align = block(Direction.Left, { pc = 33 }),
	})
	local sec = ui_element({
		display = "second_b_text",
		widgets = { text("Play") },
	})
	local second_b = ui_element({
		display = "second_b",
		widgets = { button(nil, sec) },
		align = block(Direction.Left, { pc = 55 }),
	})

	local third = ui_element({
		display = "first_b_text",
		widgets = { text("Mods") },
	})
	local third_b = ui_element({

		display = "third_b",
		widgets = { button(nil, third) },
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
	local up_panel = ui_element({
		display = "up_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 40 }),
	})
	local middle_panel = ui_element({
		display = "middle_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 50 }),
	})
	local down_panel = ui_element({
		display = "down_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 100 }),
	})
	-- NOTE: RIGHT SIDE

	local right_width = 638
	-- NOTE: RIGHT HEADER
	local first_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.collections1) },
	})
	local first_header_b = ui_element({
		display = "first_header_b",
		widgets = { button(nil, first_header) },
		align = block(Direction.Right, { px = 200 }),
	})

	local second_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.sort1) },
	})
	local second_header_b = ui_element({
		display = "second_header_b",
		widgets = { button(nil, second_header) },
		align = block(Direction.Right, { px = 245 }),
	})

	local third_header = ui_element({
		display = "right_header_icon",
		widgets = { text(icons.filter1) },
	})
	local third_header_b = ui_element({
		display = "third_header_b",
		widgets = { button(nil, third_header) },
		align = block(Direction.Right, { px = 200 }),
	})

	local up_header = ui_element({
		widgets = {},
		align = block(Direction.Up, { px = 88 }),
	})
	up_header:push_child(third_header_b)
	up_header:push_child(second_header_b)
	up_header:push_child(first_header_b)

	-- NOTE: RIGHT SCROLL
	local main_list = ui_element({
		display = "header",
		widgets = { box() },
		align = block(Direction.Left, { px = right_width - (40 * 2) }),
		up_panel,
	})
	local middle_pannel = ui_element({
		widgets = {},
		align = block(Direction.Right, { px = right_width - 40 }),
		up_panel,
	})
	middle_pannel:push_child(main_list)
	-- NOTE: RIGHT FOOTTER

	local down_footer = ui_element({
		widgets = {},
		display = "header",
		widgets = { box() },
		align = block(Direction.Down, { px = 88 }),
	})
	-- NOTE: MAIN LAYOUT
	local left_p = ui_element({
		widgets = {},
		align = absolute({
			pivot = { x = 0, y = 50 },
			parent_pivot = { x = 0, y = 50 },
			size = Size({ px_hor = 750, per_vert = 100 }),
		}), -- TODO:  :animation({ key = "test_animation", delta_pos= { x = -750, y =0 },delta_pos= { x = -750, y =0 }, delta_size= {...}, ease_fn ="in", length_ms = 300}
	})
	left_p:push_child(bottom_bp)
	left_p:push_child(up_panel)
	left_p:push_child(middle_panel)
	left_p:push_child(down_panel)

	local right_p = ui_element({
		widgets = {},
		align = block(Direction.Right, { px = right_width }),
	})
	right_p:push_child(up_header)
	right_p:push_child(down_footer)
	right_p:push_child(middle_pannel)

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
	-- local lv = list_view(bar)

	-- local item_height = 48
	-- for _, title in ipairs(songs) do
	-- 	local txt = ui_element({ display = "main_text", widgets = { text(title) } })
	-- 	local item = ui_element({
	-- 		display = "list_item",
	-- 		widgets = { button(nil, txt) },
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

	ctx.ui.root_elements = { root, root_window }

	ctx.ui.need_to_realign = true
end
