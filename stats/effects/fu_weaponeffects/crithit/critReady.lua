function init()
  activateVisualEffects()
  effect.setParentDirectives("fade=008800=0.2")
  self.timer = 10
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("critText", statusTextRegion)
  animator.burstParticleEmitter("critText")
  animator.playSound("burn")
 -- animator.burstParticleEmitter("smoke")
end



function update(dt)

end


function uninit()
 
end
