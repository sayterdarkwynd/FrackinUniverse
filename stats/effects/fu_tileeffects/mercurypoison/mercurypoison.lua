function init()
  _x = effect.configParameter("healthDown", 0)
baseValue = effect.configParameter("healthDown",0)*(status.resourceMax("health"))

  if (status.resourceMax("health")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
     else
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  end
  
  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.0
  self.tickTime = 3.0
  self.tickTimer = self.tickTime  
  activateVisualEffects()
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
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

  effect.setParentDirectives("fade=EEEEEE="..self.tickTimer * 0.4)

end

function uninit()
  
end