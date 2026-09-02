local execute = {
  Quit = function()
  end,
  quit = function()
    love.event.push("quit") -- same as the osu_ui example: the loop polls it and exits
  end,
  print_a = function()
    print("pressed button A")
  end,
  print_b = function()
    print("pressed button B")
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
