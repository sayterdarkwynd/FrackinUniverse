function init()
  script.setUpdateDelta(5)
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  self.baseDamage = setEffectDamage()
  self.baseTime = setEffectTime()
  activateVisualEffects()
end

function setEffectDamage()
  self.baseValue = config.getParameter("healthDown",0)
  return ( self.baseValue *  (1 -status.stat("poisonResistance",0) )  )
end

function setEffectTime()
  return (  self.tickTimer *  math.min(   1 - math.min( status.stat("poisonResistance",0) ),0.45))
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function deactivateVisualEffects()
  animator.setParticleEmitterActive("drips", false)
end

function update(dt)

  	if ( status.stat("poisonResistance",0)  >= 0.5 ) then
  	  deactivateVisualEffects()
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

  effect.setParentDirectives("fade=AA00AA="..self.tickTimer * 0.4)
end


function uninit()
  
end