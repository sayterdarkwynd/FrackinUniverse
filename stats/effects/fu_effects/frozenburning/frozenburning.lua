function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.setParticleEmitterOffsetRegion("frozenfiretrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("frozenfiretrail", true)
  effect.setParentDirectives("fade=AC00BF=0.25")

  script.setUpdateDelta(5)
  self.baseModifier = 0
  self.tickTime = 1.0
  self.tickTimer = self.tickTime

  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.15}
  })

end

function update(dt)
  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end

  mcontroller.controlModifiers({
      groundMovementModifier = 0.3,
      speedModifier = 0.75,
      airJumpModifier = 0.85
    })

  self.tickTimer = self.tickTimer - dt

  self.baseModifier = status.stat("fireResistance")
  if self.baseModifier >= 0.6 then
    self.baseModifier = 2.5
  elseif self.baseModifier >= 0.4 then
    self.baseModifier = 1.75
  elseif self.baseModifier >= 0.2 then
    self.baseModifier = 1
  else
   self.baseModifier = 0
  end

  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 3 - self.baseModifier,
        damageSourceKind = "ice",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()

end
