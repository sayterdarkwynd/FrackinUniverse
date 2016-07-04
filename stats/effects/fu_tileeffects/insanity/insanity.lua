function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.0001
  self.tickTime = 5.0
  self.tickTimer = self.tickTime
  activateVisualEffects()
  self.timers = {} 
  _x = config.getParameter("defenseModifier", 0)
  baseValue = config.getParameter("defenseModifier",0)*(status.stat("protection"))
  effect.addStatModifierGroup({{stat = "protection", amount = baseValue }})
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "poison",
        sourceEntityId = entity.id()
      })
  end
end


function uninit()
  
end