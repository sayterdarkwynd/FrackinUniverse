function init()
	script.setUpdateDelta(5)
	if not world.entitySpecies(entity.id()) then return end

	self.tickDamagePercentage = 0.025
	self.tickTime = 1.2
	self.tickTimer = self.tickTime

	self.healingRate = 1.0 / config.getParameter("healTime", 60)
	bonusHandler=bonusHandler or effect.addStatModifierGroup({})
	self.frEnabled=status.statusProperty("fr_enabled")
	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	if self.frEnabled and (self.species == "fragmentedruin") then
		animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
		animator.setParticleEmitterActive("drips", true)
	else
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
		animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
		animator.setParticleEmitterActive("healing", config.getParameter("particles", true))  
	end
	self.didInit=true
end

function update(dt)
	if (not self.didInit) or (not self.healingRate) then init() end
	--sb.logInfo("regenhealingwater")
	if self.frEnabled and (self.species == "fragmentedruin") then
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
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})

		--status.modifyResourcePercentage("health", self.healingRate * dt)
	end

end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end