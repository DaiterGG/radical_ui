-- view.lua: main view entry point.
-- All actual UI content is in separate "test" / screen modules under view/.

local main_view = require("view.main_view")

return function(ctx)
	main_view(ctx)
	-- test_view(ctx)
end
