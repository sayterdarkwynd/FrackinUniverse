
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.regenInterval = config.getParameter("regenInterval", 0)
	self.energyToHealth = config.getParameter("energyToHealth", 0)
	
	baseInit()
end

function update(dt)
	if self.regenInterval <= 0 then
		local health = status.resource("health")
		if health < status.resourceMax("health") then
			if status.consumeResource("energy", self.energyToHealth) then
				status.giveResource("health", 1)
			end
			
			status.setResourcePercentage("energyRegenBlock", 1)
		end
		
		self.regenInterval = config.getParameter("regenInterval", 0)
	else
		self.regenInterval = self.regenInterval - dt
	end
	
	baseUpdate(dt)
end

function uninit()
	baseUninit()
end