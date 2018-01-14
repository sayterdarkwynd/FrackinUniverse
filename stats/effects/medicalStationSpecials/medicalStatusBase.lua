function baseInit()
	effect.modifyDuration(300 - effect.duration())
	
	self.checkInterval = 10
	self.checkCooldown = 0
end

function baseUpdate(dt)
	if status.statusProperty("fuEnhancerActive", false) then
		if self.checkCooldown <= 0 then
			self.checkCooldown = self.checkInterval
			effect.modifyDuration(300 - effect.duration())
		else
			self.checkCooldown = self.checkCooldown - dt
		end
	else
		effect.expire()
	end
end

function baseUninit()
	if modifierGroupID then
		effect.removeStatModifierGroup(modifierGroupID)
	end
end