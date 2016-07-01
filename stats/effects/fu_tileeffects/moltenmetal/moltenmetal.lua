function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.044
  self.tickTime = 0.85
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
        damageSourceKind = "fireplasma",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives("fade=AA00AA="..self.tickTimer * 0.4)
end


function uninit()
  
end