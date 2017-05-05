function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  script.setUpdateDelta(5)
  self.tickTime = 0.5
  self.tickTimer = self.tickTime
  self.baseDamage = setEffectDamage()
  self.baseTime = setEffectTime()   
end

function setEffectDamage()
  self.baseValue = config.getParameter("healthDown",0)
  return ( self.baseValue *  (1 -status.stat("physicalResistance",0) )  )
end

function setEffectTime()
  return (  self.tickTimer *  math.min(   1 - math.min( status.stat("physicalResistance",0) ),0.45))
end

function update(dt)
  	if ( status.stat("physicalResistance",0)  >= 0.90 ) then
	  effect.expire() 
	end  
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.baseDamage,
        damageSourceKind = "default",
        sourceEntityId = entity.id()
      })
  end
  effect.setParentDirectives("fade=00AA00="..self.tickTimer * 0.4)
end

function uninit()
  
end