function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
  --status.modifyResourcePercentage("health", self.healingRate * dt)
  effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
