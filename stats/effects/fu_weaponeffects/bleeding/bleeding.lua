function init()
  self.source=effect.sourceEntity()
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
	local damageVal
	if status.statPositive("specialStatusImmunity") then
		damageVal=math.floor(world.threatLevel() * self.tickDamagePercentage * 100)
	else
		damageVal=math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1
	end
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = damageVal,
        damageSourceKind = "bow",
        sourceEntityId = self.source
      })
	  end
	end

function uninit()

end
