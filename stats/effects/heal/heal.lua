function init()
	animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("healing", true)

	--script.setUpdateDelta(5)
	self.penaltyRate = config.getParameter("penaltyRate",0)
	self.healingRate = config.getParameter("healAmount", 5) / effect.duration()
	self.healingBonus = status.stat("healingBonus") or 0
	self.healingRate = self.healingRate + self.healingBonus
	bonusHandler=effect.addStatModifierGroup({{stat="healthRegen",amount=(self.healingRate - self.penaltyRate)}})
end

--[[function update(dt)
	--sb.logInfo("heal")
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=(self.healingRate - self.penaltyRate)}})
    --status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt)
end]]

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
