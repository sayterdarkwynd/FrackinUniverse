require "/scripts/status.lua"
function init()
self.listener = damageListener("damageTaken", function(note)
suffer = note[1]["damageDealt"]
source = note[1]["damageSourceKind"]
if source == "poison" then
status.modifyResource("health", -suffer * 2)
end
end)
script.setUpdateDelta(2)
end

function update(dt)
self.listener:update()
end

function uninit()
end