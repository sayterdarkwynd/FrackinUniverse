function init()
  if status.stat("isCharged") == 1 then
    activateVisualEffects()
  end
  self.timer = 10
  script.setUpdateDelta(10)
end


function activateVisualEffects()
 if status.stat("isCharged") == 1 then
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("critText", statusTextRegion)
  animator.burstParticleEmitter("critText")
  animator.playSound("burn")
  -- animator.burstParticleEmitter("smoke") 
  effect.setParentDirectives("fade=008800=0.2")
 end

end



function update(dt)

end


function uninit()
 
end
