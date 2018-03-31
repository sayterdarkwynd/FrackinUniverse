
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	local modifierTable = {
		{stat = "maxEnergy", amount = config.getParameter("energyMax", 0)},
		{stat = "foodDelta", effectiveMultiplier = config.getParameter("foodDeltaMult", 0)},
		{stat = "energyRegenBlockTime", amount = config.getParameter("energyBlockIncrease", 0)},
		{stat = "energyRegenPercentageRate", effectiveMultiplier = config.getParameter("energyRegenMult", 0)}
	}
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end