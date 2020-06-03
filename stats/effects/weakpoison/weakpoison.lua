function init()
	if world.entitySpecies(entity.id()) == "fragmentedruin" then
		animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
		animator.setParticleEmitterActive("healing", config.getParameter("particles", true))  
	else
		animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
		animator.setParticleEmitterActive("drips", true)  
	end

	script.setUpdateDelta(5)

	self.tickDamagePercentage = 0.025
	self.tickTime = 1.2
	self.tickTimer = self.tickTime

	self.penaltyRate = config.getParameter("penaltyRate",0)
	self.healingRate = config.getParameter("healAmount", 5) / effect.duration()
	self.healingBonus = status.stat("healingBonus") or 0
	self.healingRate = self.healingRate + self.healingBonus
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if world.entitySpecies(entity.id()) == "fragmentedruin" then
		--sb.logInfo("weakpoison")
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=(self.healingRate - self.penaltyRate)}})
		--status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt)
	else
		if (status.stat("poisonResistance",0) <= 0.45) then
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
		else
			effect.expire()
		end
	end

end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)

end
