function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	effect.setParentDirectives("fade=8a6818=0.2")
	script.setUpdateDelta(5)
	self.tickDamagePercentage = 0.03
	self.tickTime = 1.0
	self.tickTimer = self.tickTime

	warningResource="ffbiomesulphuricwarning"
	if status.isResource(warningResource) then
		if not status.resourcePositive(warningResource) then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomesulphuric", 1.0)
		end
		status.setResourcePercentage(warningResource,1.0)
	else
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomesulphuric", 1.0)
	end
end



function update(dt)
	mcontroller.controlModifiers({
		groundMovementModifier = 0.85,
		runModifier = 0.85,
		jumpModifier = 0.85
	})

	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 2,
			damageSourceKind = "poison",
			sourceEntityId = entity.id()
		})
	end
	if status.isResource(warningResource) then
		warningTimer=(warningTimer or 0)+dt
		if warningTimer>1 then
			status.setResourcePercentage(warningResource,1.0)
		end
	end
end

function uninit()

end