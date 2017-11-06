function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=BF3300=0.25")
  animator.playSound("burn", -1)
  
  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.025
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  
  self.baseDmg = 6

end


function setEffectDamage()
  return ( ( self.baseDmg ) *  (1 -status.stat("fireResistance",0) ) )
end


function update(dt)
  if (status.stat("fireResistance") <= 0.65) then
  	self.damageApply = setEffectDamage() 
	  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
	    effect.expire()
	  end
	  self.tickTimer = self.tickTimer - dt
	  if self.tickTimer <= 0 then

	    self.tickTimer = self.tickTime

	    status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = self.damageApply,
		damageSourceKind = "fire",
		sourceEntityId = entity.id()
	      })

	  end    
  end
end


function uninit()
  
end
