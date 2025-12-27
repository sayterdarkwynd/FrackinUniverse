function init()
	script.setUpdateDelta(3)
	self.researchPerSecond = config.getParameter("researchPerSecond",0)
	self.damageAmount = config.getParameter("damageAmount",0)
	self.timer = 0
	self.hasStarted = 0
	animator.setParticleEmitterOffsetRegion("insane", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("insane", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("insane", true)
	activateVisualEffects()
end

function update(dt)
	if world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") or (entity.entityType() ~= "player") then
		return
	end
	self.timer = self.timer - dt
	if (self.timer <= 0) then
		self.timer = 1
		world.spawnItem("fumadnessresource",entity.position(),self.researchPerSecond)--create the Madness item here in the amount of baseValue.
		animator.playSound("madness")
		self.healthDamage = ((math.max(1.0 - status.stat("mentalProtection"),0))*self.damageAmount) + status.stat("madnessModifier")
		status.applySelfDamageRequest({damageType = "IgnoresDef",damage = self.healthDamage,damageSourceKind = "shadow",sourceEntityId = entity.id()})
		activateVisualEffects()
	end
end

function activateVisualEffects()
	effect.setParentDirectives("fade=765e72=0.4")
	if entity.entityType()=="player" then
		if self.hasStarted == 0 then
			self.hasStarted = 1
			local statusTextRegion = { 0, 1, 0, 1 }
			animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
			animator.burstParticleEmitter("statustext")
		end
	end
end

function uninit()
	effect.removeStatModifierGroup(penaltyHandler)
	effect.removeStatModifierGroup(baseHandler)
end
