function init()
 --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})

  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
if entity.entityType()=="player" then
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  end
end


function update(dt)

end

function uninit()
end
