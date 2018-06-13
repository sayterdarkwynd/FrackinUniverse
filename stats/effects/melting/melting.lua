function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=FF8800=0.2")

  script.setUpdateDelta(5)

  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  self.damage = 30

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = 30,
      damageSourceKind = "fire",
      sourceEntityId = entity.id()
    })
    
 self.damage = setEffectDamage()
end


function setEffectDamage()
  return ( self.damage *  (1 -status.stat("fireResistance",0) )  )
end

function update(dt)

  if ( status.stat("fireResistance",0)  >= 1.0 ) then
    effect.expire() 
  end  

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.damage = self.damage + 5
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.damage,
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end
end

function onExpire()
  status.addEphemeralEffect("burning")
end
