
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	local modifierTable = {}
	for _, immunityStat in ipairs(config.getParameter("statImmunities", 0)) do
		table.insert(modifierTable, {stat = immunityStat, amount = 1})
	end
	
	for _, resist in ipairs(config.getParameter("resistances", 0)) do
		table.insert(modifierTable, {stat = resist, effectiveMultiplier = config.getParameter("allResistMult", 0)})
	end
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end