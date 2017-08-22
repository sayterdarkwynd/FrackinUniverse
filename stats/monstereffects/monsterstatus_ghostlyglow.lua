local fu_monsters_init = init
local fu_monsters_update = update
local fu_monsters_uninit = uninit

function init()
  fu_monsters_init()
  status.addEphemeralEffect("ghostlyglow",math.huge)
end

function update(dt)
  fu_monsters_update(dt)
end

function uninit()
end
