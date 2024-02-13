function init()
	script.setUpdateDelta(5)
	self.tickDamagePercentage = 0.0005
	self.tickTime = 5.0
	self.tickTimer = self.tickTime
	activateVisualEffects()
	self.timers = {}
	animator.setParticleEmitterOffsetRegion("statustext", { 0, 1, 0, 1 })
	--animator.setParticleEmitterOffsetRegion("statustext2", { 0, 1, 0, 1 })
	typerParticle.init()
end

function activateVisualEffects()
	if entity.entityType()=="player" then
		animator.burstParticleEmitter("statustext")
	end
end
function activateVisualEffects2()
	if entity.entityType()=="player" then
		animator.burstParticleEmitter("statustext2")
	end
end

function update(dt)
	if ( status.stat("shadowResistance") >= 0.60 ) and ( status.stat("cosmicResistance") >= 0.60 ) then
		--effect.expire()--used in an effect zone, do not use this.
		self.tickTimer=self.tickTime
		return
	end

	if world.entityType(entity.id()) == "player" then
		status.addEphemeralEffect( "insanityblurstat")
	end
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
			damageSourceKind = "poison",
			sourceEntityId = entity.id()
		})
		activateVisualEffects2()
	end
	typerParticle.update(dt)
end
