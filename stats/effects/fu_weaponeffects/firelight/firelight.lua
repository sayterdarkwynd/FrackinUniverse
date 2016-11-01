function init()
  animator.playSound("burn", -1)
  --script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.05
  self.tickTime = 1.0
  self.tickTimer = 0

  self.timer = 0

  self.stage1 = false
  self.stage2 = false
  self.stage3 = false
end

function update(dt)

  self.timer = self.timer + dt

  --sb.logInfo("timer: %s", self.timer)

  if self.timer > 3.2 then
    effect.setParentDirectives("fade=BF3300=0.7")
    self.tickTimer = self.tickTimer - dt
    if self.tickTimer <= 0 then
      self.tickTimer = self.tickTime
      status.applySelfDamageRequest({
          damageType = "IgnoresDef",
          damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
          damageSourceKind = "fire",
          sourceEntityId = entity.id()
        })
    end
    self.stage3 = true
    self.stage2 = false
  elseif self.timer > 1.6 then
    effect.setParentDirectives("fade=BF3300=0.5")
    animator.setParticleEmitterActive("flames", true)
    animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
    self.stage2 = true
    self.stage1 = false
  else
    effect.setParentDirectives("fade=BF3300=0.2")
    animator.setParticleEmitterActive("flames", false)
    self.stage1=true
  end

  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end

  if effect.duration() < 0.1 then
    if self.stage3 then
      effect.modifyDuration(1.5)
      self.stage3 = false
      self.stage2 = true
      self.timer = 1.5
    elseif self.stage2 then
      effect.modifyDuration(1.5)
      self.stage2 = false
      self.stage1 = true
      self.timer = 0
    else
      self.stage1 = false
      self.timer = 0
    end
  end



end

function uninit()

end


