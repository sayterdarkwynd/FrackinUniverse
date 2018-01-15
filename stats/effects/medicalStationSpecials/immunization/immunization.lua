
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	local modifierTable = {
		{stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMult", 0)},
		{stat = "protection", effectiveMultiplier = config.getParameter("protectionMult", 0)}
	}
	
	for _, immunityStat in ipairs(config.getParameter("statImmunities", 0)) do
		table.insert(modifierTable, {stat = immunityStat, amount = 1})
	end
	
	self.ephemeralResist = config.getParameter("statusesWithoutBlockingStat", 0)
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	for _, effect in ipairs(self.ephemeralResist) do
		status.removeEphemeralEffect(effect)
	end
	
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end