
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.dummyStatus = "medicalglasscannondummy"
	
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "protection", effectiveMultiplier = config.getParameter("protectionMultiplier", 0)},
		{stat = "powerMultiplier", effectiveMultiplier = config.getParameter("powerMultiplier", 0)}
	})
	
	baseInit(self.dummyStatus)
end

function update(dt)
	baseUpdate(dt, self.dummyStatus)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
end