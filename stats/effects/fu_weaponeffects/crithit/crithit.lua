function init()
  activateVisualEffects()
  effect.setParentDirectives("fade=cc0000=0.2")
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  --animator.playSound("burn")
   -- animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
   -- animator.setParticleEmitterActive("smoke", true)

end



function update(dt)
 
end


function uninit()
 
end
