function init()
  animator.setParticleEmitterOffsetRegion("slug", mcontroller.boundBox())
  animator.setParticleEmitterActive("slug", true)
  effect.addStatModifierGroup({
    {stat = "energyRegenPercentageRate", baseMultiplier = 0.50},
    {stat = "energyRegenBlockTime", baseMultiplier = 1.35},
    {stat = "fallDamageMultiplier", amount = 0.85},
    {stat = "foodDelta", baseMultiplier = 1.25},
    {stat = "aetherImmunity", amount = 1}
  })  
end

function update(dt)
  mcontroller.controlParameters({
        airForce = 35.0,
        groundForce = 23.5,
        runSpeed = 17.0
    })
  mcontroller.controlModifiers({
      speedModifier = 1.40
    })    
end

function uninit()

end
