function init()
  if status.stat("isCharged") == 1 then 
    activateVisualEffects() 
  end
  self.timer = 0.5
  script.setUpdateDelta(5)
end


function activateVisualEffects()
 if status.stat("isCharged") == 1 then
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("reloadText", statusTextRegion)
  animator.burstParticleEmitter("reloadText")
  effect.setParentDirectives("fade=0055aa=0.2")
 end

end



function update(dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
  else
    effect.die()
  end
end


function uninit()
 
end
