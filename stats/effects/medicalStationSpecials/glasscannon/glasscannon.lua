
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "protection", effectiveMultiplier = config.getParameter("protectionMultiplier", 0)},
		{stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMultiplier", 0)}
	})
	
	baseInit()
end

function update(dt)
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end