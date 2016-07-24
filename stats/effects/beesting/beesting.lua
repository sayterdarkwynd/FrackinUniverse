function init()
  animator.setParticleEmitterOffsetRegion("bees", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("bees", config.getParameter("emissionRate", 2))
  animator.setParticleEmitterActive("bees", true)

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.010
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
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
end

function uninit()
  
end