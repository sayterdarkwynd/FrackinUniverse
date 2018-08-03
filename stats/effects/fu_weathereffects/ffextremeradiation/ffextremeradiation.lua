function init()
	animator.setParticleEmitterOffsetRegion("flamesfu", mcontroller.boundBox())
	animator.setParticleEmitterActive("flamesfu", true)
	effect.setParentDirectives("fade=00FFBB=0.15")
	script.setUpdateDelta(5)
	self.tickDamagePercentage = 0.032
	self.tickTime = 1.0
	self.tickTimer = self.tickTime
	
	warningResource="ffbiomeradiationwarning"
	if status.isResource(warningResource) then
		if not status.resourcePositive(warningResource) then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeradiation", 1.0)
		end
		status.setResourcePercentage(warningResource,1.0)
	else
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeradiation", 30.0)
	end
end



function update(dt)
	mcontroller.controlModifiers({
		groundMovementModifier = 0.90,
		runModifier = 0.80,
		jumpModifier = 0.80
	})

	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
			damageSourceKind = "hellfireweapon",
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