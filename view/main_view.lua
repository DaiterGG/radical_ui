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
	if not ctx.ui.need_to_realign then
		return
	end
	ctx.ui.need_to_realign = false

	local header = ui_element({
		display = "header",
		widgets = { box() },
		align = block(Direction.Up, { pc = 5 }),
	})

	local buttons_ic =
		{ { icons.back2, "quit" }, { icons.cog1, "quit" }, { icons.brush1, "quit" }, { icons.online1, "quit" } }
	for _, b in pairs(buttons_ic) do
		local header_b_icon = ui_element({
			display = "header_left_b_icons",
			widgets = { text(b[1]) },
		})
		local header_b = ui_element({
			display = "header_left_b",
			widgets = { button(b[2], header_b_icon) },
			align = block(Direction.Left, { pc = 8 }),
		})

		header:push_child(header_b)
	end

	local first = ui_element({
		display = "first_b_text",
		widgets = { text("Input") },
	})
	local first_b = ui_element({
		display = "first_b",
		widgets = { button(first) },
		align = block(Direction.Left, { pc = 33 }),
	})
	local sec = ui_element({
		display = "second_b_text",
		widgets = { text("Play") },
	})
	local second_b = ui_element({
		display = "second_b",
		widgets = { button(sec) },
		align = block(Direction.Left, { pc = 50 }),
	})

	local third = ui_element({
		display = "first_b_text",
		widgets = { text("Input") },
	})
	local third_b = ui_element({

		display = "third_b",
		widgets = { button(third) },
		align = block(Direction.Left, { pc = 100 }),
	})
	local bottom_bp = ui_element({
		widgets = {},
		align = block(Direction.Down, { pc = 10 }),
	})
	bottom_bp:push_child(first_b)
	bottom_bp:push_child(second_b)
	bottom_bp:push_child(third_b)
	-- NOTE: GLASS PANELS
	local up_panel = ui_element({
		display = "up_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 36 }),
	})
	local middle_panel = ui_element({
		display = "middle_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 45 }),
	})
	local down_panel = ui_element({
		display = "down_panel",
		widgets = { box() },
		align = block(Direction.Up, { pc = 100 }),
	})

	-- NOTE: MAIN LAYOUT
	local left_p = ui_element({
		widgets = {},
		align = block(Direction.Left, { px = 750 }),
	})

	left_p:push_child(bottom_bp)
	left_p:push_child(up_panel)
	left_p:push_child(middle_panel)
	left_p:push_child(down_panel)

	local root = ui_element({
		display = "root",
		widgets = { box() },
		align = absolute({
			pivot = { x = 0, y = 0 },
			parent_pivot = { x = 0, y = 0 },
			size = Size({ per_hor = 100, per_vert = 100 }),
		}),
	})

	test_p = ui_element({
		display = "test_p",
		widgets = { button(first) },
		align = absolute({
			pivot = { x = 0, y = 100 },
			parent_pivot = { x = 0, y = 100 },
			size = Size({ per_hor = 20, per_vert = 10 }),
		}),
	})
	root:push_child(test_p)
	-- root:push_child(header)
	-- root:push_child(left_p)

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

	ctx.ui.root_elements = { root }

	ui_manager.align(ctx)
end
