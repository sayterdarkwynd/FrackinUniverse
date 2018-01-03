
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.dummyStatus = "medicalberserkdummy"
	self.speedMultiplier = config.getParameter("speedMultiplier", 0)
	
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "protection", amount = config.getParameter("protection", 0)},
		{stat = "grit", amount = config.getParameter("grit", 0)},
		{stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMultiplier", 0)}
	})
	
	baseInit(self.dummyStatus)
end

function update(dt)
	mcontroller.controlModifiers({ speedModifier = self.speedMultiplier })
	baseUpdate(dt, self.dummyStatus)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
end