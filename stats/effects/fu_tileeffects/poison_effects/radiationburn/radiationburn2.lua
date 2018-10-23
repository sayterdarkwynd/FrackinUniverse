function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.setParticleEmitterActive("fx", true)
  effect.setParentDirectives("fade=00FF33=0.15")
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.2
  self.tickTime = 0.05
  self.tickTimer = self.tickTime
end



function update(dt)
	if (status.stat("radioactiveResistance",0)  >= 2) then
	  effect.expire()
	end
	
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1.5,
        damageSourceKind = "radioactive",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()

end
