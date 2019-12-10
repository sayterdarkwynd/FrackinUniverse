function init()
  self.used = 0
  if (status.stat("isCharged") == 1) and (self.used == 0) then
    self.used = 1
    activateVisualEffects()
    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
  end
end

function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("critText", statusTextRegion)
  animator.burstParticleEmitter("critText")
  animator.playSound("burn")
  effect.setParentDirectives("fade=008800=0.2")
end


function update(dt)

end

function uninit()
end
