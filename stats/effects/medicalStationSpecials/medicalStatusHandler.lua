

function init()
	self.checkInterval = 0.5
	self.checkCooldown = 0
end

function update(dt)
	if self.checkCooldown <= 0 then
		local effect = status.statusProperty("fuEnhancerActive", false)
		if effect then
			status.addEphemeralEffect(effect, 100, entity.id())
		end
		
		self.checkCooldown = self.checkInterval
	else
		self.checkCooldown = self.checkCooldown - dt
	end
end