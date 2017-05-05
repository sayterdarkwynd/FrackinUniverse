function init()
  animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
  animator.setParticleEmitterActive("snow", true)
  script.setUpdateDelta(5)
  self.tickTime = 0.7
  self.tickTimer = self.tickTime
  self.baseDamage = setEffectDamage()
  self.baseTime = setEffectTime() 
end


function setEffectDamage()
  self.baseValue = config.getParameter("healthDown",0)
  return ( self.baseValue *  (1 -status.stat("iceResistance",0) )  )
end

function setEffectTime()
  return (  self.tickTimer *  math.min(   1 - math.min( status.stat("iceResistance",0) ),0.45))
end

function update(dt)
  	if ( status.stat("iceResistance",0)  >= 0.75 ) then
  	  deactivateVisualEffects()
	  effect.expire() 
	end  
  mcontroller.controlModifiers({
        groundForce = 60.5,
        slopeSlidingFactor = 0.6,  
        groundMovementModifier = 0.45,
        runModifier = 0.65,
        jumpModifier = 0.75
    })

  mcontroller.controlParameters({
      normalGroundFriction = 4.675
    })
    
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.baseDamage,
        damageSourceKind = "ice",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives("fade=66FFFF="..self.tickTimer * 0.4)
end

function uninit()

end