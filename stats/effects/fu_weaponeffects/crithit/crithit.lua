function init()
  --animator.playSound("burn")
  activateVisualEffects()
  --effect.setParentDirectives("fade=770000=0.25")
  script.setUpdateDelta(2)

end


function activateVisualEffects()
  local statusTextRegion = { 0, 0, 0, 0 }
  animator.setParticleEmitterOffsetRegion("smoke", statusTextRegion)
  animator.burstParticleEmitter("smoke")
end



function update(dt)

end


function uninit()

end
