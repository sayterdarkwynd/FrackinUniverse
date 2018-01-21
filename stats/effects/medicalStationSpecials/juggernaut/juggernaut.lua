
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.speedMultiplier = config.getParameter("speedMultiplier", 0)
	
	local modifierTable = {
		{stat = "knockbackThreshold", amount = math.huge},
		{stat = "protection", amount = config.getParameter("protection", 0)}
	}
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	mcontroller.controlModifiers({ speedModifier = self.speedMultiplier })
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
	baseUninit()
end