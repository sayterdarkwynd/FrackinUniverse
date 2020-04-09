function init()
  activateVisualEffects() 
  self.timer = 0.5
  script.setUpdateDelta(5)
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  if entity.entityType()=="player" then
  animator.setParticleEmitterOffsetRegion("reloadText", statusTextRegion)
  animator.burstParticleEmitter("reloadText")
  end
  effect.setParentDirectives("fade=0055aa=0.2")
  --animator.burstParticleEmitter("smoke")
end



function update(dt)

end


function uninit()
 
end
