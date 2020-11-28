function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 6))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)
  self.penaltyRate = config.getParameter("penaltyRate",0)
  self.healingRate = config.getParameter("healAmount", 1.5) / effect.duration()
  bonusHandler=effect.addStatModifierGroup({})
  effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*math.max(0, 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
end

function update(dt)
    --status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=((self.healingRate*math.max(0, 1 + status.stat("healingBonus") )) - self.penaltyRate)}})
end

function uninit()

end