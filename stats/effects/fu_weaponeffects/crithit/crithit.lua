function init()
  activateVisualEffects()
  effect.setParentDirectives("fade=770000=0.25")
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  --local statusTextRegion = { 0, 1, 0, 1 }
  --animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  --animator.burstParticleEmitter("statustext")
  --animator.playSound("burn")
  --animator.burstParticleEmitter("smoke")
end



function update(dt)
 
end


function uninit()
 
end
