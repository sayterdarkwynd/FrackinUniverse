require "/scripts/unifiedGravMod.lua"

function init()
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
	effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
end

function update(dt)
	unifiedGravMod.refreshGrav(dt)
end
