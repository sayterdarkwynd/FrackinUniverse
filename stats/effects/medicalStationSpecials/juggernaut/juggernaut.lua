
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.dummyStatus = "medicaljuggernautdummy"
	self.speedMultiplier = config.getParameter("speedMultiplier", 0)
	
	local modifierTable = {
		{stat = "knockbackThreshold", amount = math.huge},
		{stat = "protection", amount = config.getParameter("protection", 0)}
	}
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit(self.dummyStatus)
end

function update(dt)
	mcontroller.controlModifiers({ speedModifier = self.speedMultiplier })
	baseUpdate(dt, self.dummyStatus)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
	baseUninit(self.dummyStatus, nil)
end