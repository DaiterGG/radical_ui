-- keybind_load.lua: default keybindings, applied once by the UI's load().
-- add your defaults here: kb.keys["key_comb"] = "action"
-- (modifier combos use ctrl+shift+alt+super order, e.g. "ctrl+shift+p")
return function(ctx)
  local kb = ctx.keybindings

  -- Esc quits the game (the game loop polls love.event for "quit")
  kb.keys["escape"] = "quit"
  kb.keys["t"] = "test_animation"
end
