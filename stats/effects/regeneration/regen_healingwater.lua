function init()
	script.setUpdateDelta(5)

	self.tickDamagePercentage = 0.025
	self.tickTime = 1.2
	self.tickTimer = self.tickTime

	self.healingRate = 1.0 / config.getParameter("healTime", 60)
	bonusHandler=effect.addStatModifierGroup({})
	if world.entitySpecies(entity.id()) == "fragmentedruin" then
		animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
		animator.setParticleEmitterActive("drips", true)
	else
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
		animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
		animator.setParticleEmitterActive("healing", config.getParameter("particles", true))  
	end
end

function update(dt)
	--sb.logInfo("regenhealingwater")
	if world.entitySpecies(entity.id()) == "fragmentedruin" then
		self.tickTimer = self.tickTimer - dt
		if self.tickTimer <= 0 then
			self.tickTimer = self.tickTime
			status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = math.ceil(status.resourceMax("health") * self.tickDamagePercentage),
				damageSourceKind = "poison",
				sourceEntityId = entity.id()
			})
		end
		effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
	--else
		--effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})

		--status.modifyResourcePercentage("health", self.healingRate * dt)
	end

end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
