
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.speedMultiplier = config.getParameter("speedMultiplier", 0)
	
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "protection", amount = config.getParameter("protection", 0)},
		{stat = "grit", amount = config.getParameter("grit", 0)},
		{stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMultiplier", 0)}
	})
	
	baseInit()
end

function update(dt)
	mcontroller.controlModifiers({ speedModifier = self.speedMultiplier })
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end