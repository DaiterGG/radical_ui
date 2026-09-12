-- view.lua: main view entry point.
-- All actual UI content is in separate "test" / screen modules under view/.

local main_view = require("view.main_view")
local ui_element = require("ui_element")
local gameplay = require("gameplay")
local align_mod = require("apply_align")

local absolute = align_mod.Absolute
local Size = align_mod.Size

local function gameplay_view(ctx)
	ctx.ui.need_to_rebuild = false
	ctx.ui.root_elements = {
		ui_element({
			widgets = { gameplay() },
			align = absolute({
				pivot = { x = 0, y = 0 },
				parent_pivot = { x = 0, y = 0 },
				size = Size({ pc_hor = 100, pc_vert = 100 }),
			}),
		}),
	}
	ctx.ui.need_to_realign = true
end

return function(ctx)
	if not ctx.ui.need_to_rebuild then
		return
	end
	ctx.ui.need_to_rebuild = false

	if ctx.ui.scene == "gameplay" then
		gameplay_view(ctx)
	else
		return main_view(ctx)
	end
end
