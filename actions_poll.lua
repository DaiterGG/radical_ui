local execute = {
  Quit = function()
  end,
}

local function poll(ctx)
  local action = ctx.action_pump:pop()
  if not action then
    return
  end
  local fn = execute[action.action]
  if fn then
    fn(action)
  end
end

return poll
