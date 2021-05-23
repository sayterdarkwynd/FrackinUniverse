function init()
	if not world.entityType(entity.id()) then return end
	self.frEnabled=status.statusProperty("fr_enabled")
	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	if self.frEnabled and (self.species == "fragmentedruin") then
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
	bonusHandler=effect.addStatModifierGroup({})
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	if self.frEnabled and (self.species == "fragmentedruin") then
		--sb.logInfo("weakpoison")
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*( 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
		--status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt)
	else
		if (status.stat("poisonResistance") <= 0.45) then
			self.tickTimer = self.tickTimer - dt
			if self.tickTimer <= 0 then
				self.tickTimer = self.tickTime
				local damageCalc=math.ceil((status.statPositive("specialStatusImmunity") and world.threatLevel()*self.tickDamagePercentage*100) or (status.resourceMax("health") * self.tickDamagePercentage))
				status.applySelfDamageRequest({
					damageType = "IgnoresDef",
					damage = damageCalc,
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
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end