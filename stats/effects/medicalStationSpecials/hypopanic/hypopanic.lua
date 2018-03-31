
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.energyPcntForMaxSpeed = config.getParameter("energyPcntForMaxSpeed", 0)
	self.maxSpeedBonus = config.getParameter("maxSpeedBonus", 0)
	self.oldHealth = status.resource("health")
	self.oldHealthPcnt = status.resourcePercentage("health")
	
	local modifierTable = {
		{stat = "maxEnergy", amount = config.getParameter("energyMax", 0)},
		{stat = "energyRegenPercentageRate", effectiveMultiplier = config.getParameter("energyRegenMult", 0)}
	}
	
	self.modifierGroupID = effect.addStatModifierGroup(modifierTable)
	baseInit()
end

function update(dt)
	if self.oldHealthPcnt ~= status.resourcePercentage("health") or self.oldHealth ~= status.resource("health") then
		if self.oldHealthPcnt > status.resourcePercentage("health") then
			local difference = self.oldHealth - status.resource("health")
			status.overConsumeResource("energy", difference)
			status.setResourcePercentage("energyRegenBlock", 0.75)
		end
		
		self.oldHealth = status.resource("health")
		self.oldHealthPcnt = status.resourcePercentage("health")
	end
	
	if status.resourcePercentage("energy") > self.energyPcntForMaxSpeed then
		local currPcnt = (status.resourcePercentage("energy") - self.energyPcntForMaxSpeed)
		local fullPcnt = (1 - self.energyPcntForMaxSpeed)
		local revPcnt = 1 - (currPcnt / fullPcnt)
		local pcntOfSpeedBonus = revPcnt * self.maxSpeedBonus
		
		mcontroller.controlModifiers({ speedModifier = 1 + pcntOfSpeedBonus })
	else
		mcontroller.controlModifiers({ speedModifier = 1 + self.maxSpeedBonus })
	end
	
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end