function init()
 --Power
  self.critChanceup = config.getParameter("critChanceMultiplier", 0)
  effect.addStatModifierGroup({{stat = "critChanceMultiplier", baseMultiplier = self.critChanceup}})
  --status.setStatusProperty("critChanceModifier", 0.2)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end


function update(dt)

end

function uninit()
end
