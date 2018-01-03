
function baseInit(dummyStatus)
	self.dummyCheckCooldown = 1
	self.killedEffects = false
	self.second = 1
	
	local foundCooldownStatus = false
	local effects = status.activeUniqueStatusEffectSummary()
	for _, e in ipairs(effects) do
		if e[1] == "medicalStatusCooldown" then
			foundCooldownStatus = true
			break
		end
	end
	
	if not foundCooldownStatus then
		status.addPersistentEffect("", "medicalStatusCooldown")
	end
	
	local timeLeft = status.statusProperty("fuMedicalEnhancerDuration", 0)
	status.addEphemeralEffect(dummyStatus, timeLeft)
end

function baseUpdate(dt, dummyStatus)
	local timeLeft = status.statusProperty("fuMedicalEnhancerDuration", 0)
	
	if self.second <= 0 then
		status.setStatusProperty("fuMedicalEnhancerDuration", timeLeft-1)
		timeLeft = timeLeft - 1
		self.second = 1
	else
		self.second = self.second - dt
	end
	
	if timeLeft <= 0 then
		if not self.killedEffects then
			status.addEphemeralEffect("medicalStatusKiller", 0.1)
			self.killedEffects = true
		end
	else
		if self.dummyCheckCooldown <= 0 then
			local foundDummy = false
			local effects = status.activeUniqueStatusEffectSummary()
			for _, e in ipairs(effects) do
				if e[1] == dummyStatus then
					foundDummy = true
					break
				end
			end
			
			if not foundDummy then
				status.addEphemeralEffect(dummyStatus, timeLeft)
			end
			
			self.dummyCheckCooldown = 1
		else
			self.dummyCheckCooldown = self.dummyCheckCooldown - dt
		end
	end
end

function baseUninit(dummyStatus, modifierGroupID)
	if modifierGroupID then
		effect.removeStatModifierGroup(modifierGroupID)
	end
end