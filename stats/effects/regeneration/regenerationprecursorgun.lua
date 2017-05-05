function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  
  effect.addStatModifierGroup({
    {stat = "protection", baseMultiplier = 1.25},
    {stat = "energyRegenPercentageRate", amount = 0.01},
    {stat = "energyRegenBlockTime", amount = 3},
    {stat = "shieldRegen", amount = 0}     
  })
  
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
  status.modifyResourcePercentage("energy", (-self.healingRate * dt) * 2)
end

function uninit()
  
end
