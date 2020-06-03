function init()
  if world.entitySpecies(entity.id()) == "fragmentedruin" then
    animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
    animator.setParticleEmitterActive("drips", true)
  else
    animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
    animator.setParticleEmitterActive("healing", config.getParameter("particles", true))  
  end

  script.setUpdateDelta(5)
  
  self.tickDamagePercentage = 0.025
  self.tickTime = 1.2
  self.tickTimer = self.tickTime
  
  self.healingRate = 1.0 / config.getParameter("healTime", 60)
end

function update(dt)
  if world.entitySpecies(entity.id()) == "fragmentedruin" then
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
    status.modifyResourcePercentage("health", self.healingRate * dt)
  end
  
end

function uninit()
  
end
