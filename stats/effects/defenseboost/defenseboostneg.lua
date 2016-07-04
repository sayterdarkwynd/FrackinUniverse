function init()
  animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
  animator.setParticleEmitterActive("snow", true)
  effect.setParentDirectives("fade=6f6f6f=0.55")
   effect.addStatModifierGroup({{stat = "protection", amount = config.getParameter("defenseAmount", 0)}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end