require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
local catInit = init

function init()
	catInit()
    if world.entitySpecies(entity.id()) == "cat" then
		status.setStatusProperty("mouthPosition", {0, -1.2})
       	status.addPersistentEffects("CatPersistantEffects",{{stat = "fallDamageMultiplier", effectiveMultiplier = 0.70}})
    end
end
