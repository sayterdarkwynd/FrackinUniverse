function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.setParticleEmitterActive("fx", true)
  effect.setParentDirectives("fade=00FF33=0.15")
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.03
  self.tickTime = 0.1
  self.tickTimer = self.tickTime
  self.statusValue = status.stat("physicalResistance",0)
end

function update(dt)
  if (status.stat("radioactiveResistance",0)  >= 0.4) then
    effect.expire()
  end
  
  
  self.tickTimer = self.tickTimer - dt
  self.statusValue = self.statusValue - 0.01
  if self.tickTimer <= 0 then
      	self.tickTimer = self.tickTime
	if self.statusValue > 0.05 then
	  status.setPersistentEffects("aciddust", { {stat = "physicalResistance", amount = self.statusValue } })
        else 
	    status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage),
		damageSourceKind = "radioactive",
		sourceEntityId = entity.id()
	    })          
	end  
  end
end

function uninit()
  status.clearPersistentEffects("aciddust")
end
