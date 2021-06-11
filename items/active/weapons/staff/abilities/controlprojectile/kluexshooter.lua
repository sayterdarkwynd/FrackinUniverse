require "/items/active/weapons/staff/abilities/controlprojectile/controlprojectile.lua"

function ControlProjectile:charged()
	self.weapon:setStance(self.stances.charged)


	animator.playSound(self.elementalType.."fullcharge")
	animator.playSound(self.elementalType.."chargedloop", -1)
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)

	self.projectileSpawnTimer = 0

	local targetValid
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		targetValid = self:targetValid(activeItem.ownerAimPosition())
		activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

		mcontroller.controlModifiers({runningSuppressed = true})

		status.setResourcePercentage("energyRegenBlock", 1.0)

		self.projectileSpawnTimer = math.max(0, self.projectileSpawnTimer - self.dt)
		if self.projectileSpawnTimer == 0 and targetValid and status.overConsumeResource("energy", self.energyPerShot) then
			self:createProjectiles()
			self.projectileSpawnTimer = self.projectileSpawnInterval
		end

		coroutine.yield()
	end

	self:setState(self.discharge)
end


function ControlProjectile:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	if #storage.projectiles > 0 then
		local delayTime = self.projectileDelayEach
		for _, projectileId in pairs(storage.projectiles) do
			if world.entityExists(projectileId) then
				world.sendEntityMessage(projectileId, "trigger", delayTime)
				delayTime = delayTime + self.projectileDelayEach
			end
		end
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
		return
	end

	util.wait(self.stances.discharge.duration, function(dt)
		status.setResourcePercentage("energyRegenBlock", 1.0)
	end)

	while #storage.projectiles > 0 do
		if self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.lastFireMode ~= self.fireMode then
			self:killProjectiles()
		end
		self.lastFireMode = self.fireMode

		status.setResourcePercentage("energyRegenBlock", 1.0)
		coroutine.yield()
	end

	animator.playSound(self.elementalType.."discharge")
	animator.stopAllSounds(self.elementalType.."chargedloop")

	self:setState(self.cooldown)
end
