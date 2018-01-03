
function init()
	self.second = 1
end

function update(dt)
	if self.second <= 0 then
		local cooldown = status.statusProperty("fuMedicalEnhancerCooldown", 0)
		if cooldown > 0 then
			status.setStatusProperty("fuMedicalEnhancerCooldown", cooldown - 1)
		end
		
		self.second = 1
	else
		self.second = self.second - dt
	end
end

-- Should never happen
function uninit() end