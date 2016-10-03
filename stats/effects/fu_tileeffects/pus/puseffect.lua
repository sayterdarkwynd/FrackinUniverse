function init()
  script.setUpdateDelta(5)
  activateVisualEffects()
  _x = config.getParameter("healthDown", 0)
baseValue = config.getParameter("healthDown",0)*(status.resourceMax("health"))

  --if (status.resourceMax("health")) * _x >= 100.0 then
  --   effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  --   else
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  --end

end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function update(dt)

end


function uninit()
  
end