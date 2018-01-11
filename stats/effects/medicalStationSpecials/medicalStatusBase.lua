function baseInit()
	status.setStatusProperty("fuEnhancerActive", true)
	effect.modifyDuration(300 - effect.duration())
	
	self.checkInterval = 10
	self.checkCooldown = 0
end

function baseUpdate(dt)
	if self.checkCooldown <= 0 then
		self.checkCooldown = self.checkInterval
		effect.modifyDuration(300 - effect.duration())
	else
		self.checkCooldown = self.checkCooldown - dt
	end
end

function baseUninit()
	status.setStatusProperty("fuEnhancerActive", false)
	
	if modifierGroupID then
		effect.removeStatModifierGroup(modifierGroupID)
	end
end