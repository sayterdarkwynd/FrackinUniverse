require "\stats\effects\fu_weathereffects\fuWeatherLib.lua"

function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	effect.setParentDirectives("fade=8a6818=0.2")
	script.setUpdateDelta(5)
	self.tickDamagePercentage = 0.03
	self.tickTime = 1.0
	self.tickTimer = self.tickTime
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
	
	warningTimer=(warningTimer or script.updateDt()*2)-dt
	if warningTimer<=0 then
		warningTimer=fuWeatherLib.warn("ffbiomesulphuricwarning","ffbiomesulphuric") and 1 or math.huge
	end
end

function uninit()

end