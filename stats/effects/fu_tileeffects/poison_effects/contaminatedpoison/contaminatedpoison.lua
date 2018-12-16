function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  script.setUpdateDelta(5)
  self.tickTime = 3.0
  self.tickTimer = self.tickTime
  self.baseDamage = config.getParameter("healthDown",0)
  self.baseTime = setEffectTime()
end

function setEffectTime()
  return self.tickTimer * math.min(1 - status.stat("poisonResistance",0), 0.45)
end

function update(dt)
  	if ( status.stat("poisonResistance",0)  >= 0.25 ) then
	  effect.expire()
	end
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.baseDamage,
        damageSourceKind = "poison",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives("fade=806e4f=0.8")

end

function uninit()

end
