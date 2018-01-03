
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.dummyStatus = "medicalrenergizerdummy"
	
	local modifierTable = {
		{stat = "maxEnergy", amount = config.getParameter("energyMax", 0)},
		{stat = "foodDelta", effectiveMultiplier = config.getParameter("foodDeltaMult", 0)},
		{stat = "energyRegenBlockTime", amount = config.getParameter("energyBlockIncrease", 0)},
		{stat = "energyRegenPercentageRate", effectiveMultiplier = config.getParameter("energyRegenMult", 0)}
	}
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit(self.dummyStatus)
end

function update(dt)
	baseUpdate(dt, self.dummyStatus)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
end