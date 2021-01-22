function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  self.energyCost = config.getParameter("energyCost")

  effect.addStatModifierGroup({
    {stat = "mentalProtection", amount = 0.25},
    {stat = "energyRegenPercentageRate", effectiveMultiplier = 0},
    {stat = "energyRegenBlockTime", effectiveMultiplier = 0},
    {stat = "shieldStaminaRegen", effectiveMultiplier = 0}
  })

end

function update(dt)
  if status.overConsumeResource("energy", self.energyCost) then
    status.modifyResourcePercentage("health", self.healingRate * dt * math.max(0,1+status.stat("healingBonus")))
    status.modifyResourcePercentage("energy", (-self.energyCost))
  end
end

function uninit()

end
