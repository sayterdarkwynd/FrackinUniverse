require "/scripts/util.lua"
require "/scripts/companions/util.lua"

function update(dt)
	if self.entityId then
		if not self.sentPowerData then
			if self.sendingPowerData and self.sendingPowerData:finished() and self.sendingPowerData:succeeded() and self.sendingPowerData:result() then
				self.sentPowerData=true
			elseif (not self.sendingPowerData) or (self.sendingPowerData and self.sendingPowerData:finished()) then
				local powerStats={}
				powerStats.powerMultiplier=projectile.powerMultiplier()
				powerStats.power=projectile.power()
				self.sendingPowerData=world.sendEntityMessage(self.entityId, "podPower",powerStats)
			end
		end
		if not self.sentSourceData then
			if self.sendingSourceData and self.sendingSourceData:finished() and self.sendingSourceData:succeeded() and self.sendingSourceData:result() then
				self.sentSourceData=true
			elseif (not self.sendingSourceData) or (self.sendingSourceData and self.sendingSourceData:finished()) then
				self.sendingSourceData=world.sendEntityMessage(self.entityId, "podSource",projectile.sourceEntity())
			end
		end
	end
	if shouldDestroy() then destroy() end
end

function hit(entityId)
	if self.hit then return end
	if world.isMonster(entityId) then
		self.hit = true
		self.entityId=entityId
		local powerStats={}
		powerStats.powerMultiplier=projectile.powerMultiplier()
		powerStats.power=projectile.power()
		self.sendingPowerData=world.sendEntityMessage(self.entityId, "podPower",powerStats)
		self.sendingSourceData=world.sendEntityMessage(self.entityId, "podSource",projectile.sourceEntity())
	end
end

function shouldDestroy()
	return (projectile.timeToLive() <= 0) or (self.hit and self.sentPowerData and self.sentSourceData)
end

function destroy()
	if self.hit then
		projectile.die()
	end
end
