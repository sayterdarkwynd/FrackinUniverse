function baseInit()
	self.checkInterval = 1
end

function baseUpdate(dt)
	if self.checkInterval <= 0 then
		if status.statusProperty("fuMedicalEnhancerDuration", 0) <= 0 then
			effect.expire()
		else
			self.checkInterval = 1
		end
	else
		self.checkInterval = self.checkInterval - dt
	end
end