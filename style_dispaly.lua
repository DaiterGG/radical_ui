local color = require("color")

local display_list = {
	root = {
		-- box = { bg = color("#004400") },
	},

	header = {
		box = {
			bg = color("#1a1a99"),
			border = { width = 1, color = color("#252525") },
		},
	},
	scrollable_list = {
		list_view = {
			bg = color("#551a1a"),
			border = { width = 1, color = color("#252525") },
		},
	},
	list_item = {
		button = {
			bg = color("#880088"),
			border = { width = 1, color = color("#882525") },
		},
	},
}

return display_list
