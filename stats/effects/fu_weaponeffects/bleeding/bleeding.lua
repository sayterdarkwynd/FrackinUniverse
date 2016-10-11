function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)
  
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.01 + config.getParameter("bleedAmount", 0)
  self.tickTime = 0.85
  self.tickTimer = self.tickTime
  effect.duration()
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "bow",
        sourceEntityId = entity.id()
      })
	  end
	end

function uninit()
  
end