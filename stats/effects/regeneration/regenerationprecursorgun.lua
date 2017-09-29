function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  
  effect.addStatModifierGroup({
    {stat = "protection", baseMultiplier = 1.25},
    {stat = "energyRegenPercentageRate", baseMultiplier = 0},
    {stat = "energyRegenBlockTime", baseMultiplier = 0},
    {stat = "shieldStaminaRegen", baseMultiplier = 0}     
  })
  
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
  if stat.resource("energy") then
    status.modifyResourcePercentage("energy", (-self.healingRate * dt) * 2)
  end
end

function uninit()
  
end
