function init()
  if (status.stat("poisonResistance",0) <= 0.45) then
    animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
    animator.setParticleEmitterActive("drips", true)
  end

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.025
  self.tickTime = 1.2
  self.tickTimer = self.tickTime
end

function update(dt)
  if (status.stat("poisonResistance",0) <= 0.45) then
	  self.tickTimer = self.tickTimer - dt
	  if self.tickTimer <= 0 then
	    self.tickTimer = self.tickTime
	    status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = math.ceil(status.resourceMax("health") * self.tickDamagePercentage),
		damageSourceKind = "poison",
		sourceEntityId = entity.id()
	      })
	  end
	  effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
  else
  effect.expire()
  end
end

function uninit()

end
