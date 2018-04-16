function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.01
  self.tickTime = 2.0
  self.tickTimer = self.tickTime
  activateVisualEffects()
end


function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("bees", mcontroller.boundBox())
  animator.setParticleEmitterActive("bees", true)
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
        damageSourceKind = "beesting",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives("fade=edcd5c="..self.tickTimer * 0.2)
end


function uninit()
  
end