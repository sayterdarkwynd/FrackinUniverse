function init()
  animator.setParticleEmitterOffsetRegion("slug", mcontroller.boundBox())
  animator.setParticleEmitterActive("slug", true)
  effect.addStatModifierGroup({{stat = "foodDelta", amount = 0.005}})
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = 0.75}})
  effect.addStatModifierGroup({{stat = "energyRegenBlockTime", amount = 1.35}})
  effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", amount = 0.08}})  
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
