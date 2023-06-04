function init()
	animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("healing", true)

	script.setUpdateDelta(5)
	self.penaltyRate = config.getParameter("penaltyRate",0)
	self.healingRate = config.getParameter("healAmount", 5) / effect.duration()
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	local species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())

	if (species == "radien") or (species == "novakid") or (species == "shadow") then
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*math.max(0, 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
		--status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt)
	else
		effect.setStatModifierGroup(bonusHandler,{})
		status.modifyResource("health", -(self.healingRate) * dt)
	end
end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end
