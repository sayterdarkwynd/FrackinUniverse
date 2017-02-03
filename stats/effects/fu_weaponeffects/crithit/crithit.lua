function init()
  activateVisualEffects()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end



function update(dt)
 
end


function uninit()
 
end
