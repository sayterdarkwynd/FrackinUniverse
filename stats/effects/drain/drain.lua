function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitter("healing", false)

  self.visualDuration = config.getParameter("visualDuration") or 0.2

  self.damageMultiplier = config.getParameter("damageMultiplier") or 0.01
  self.border = config.getParameter("border")

  self.cooldown = config.getParameter("cooldown") or 0.5

  resetDrain()
  self.cooldownTimer = 0

  if self.border then
    effect.setParentDirectives("border="..self.border)
  end

  self.queryDamageSince = 0
end

function resetDrain()
  self.cooldownTimer = self.cooldown
  self.triggerDrain = false
  self.drainTimer = 0
  self.drainDamage = 0
end

function update(dt)
  if self.cooldownTimer <= 0 then
    local damageNotifications, nextStep = status.inflictedDamageSince(self.queryDamageSince)
    self.queryDamageSince = nextStep
    for _, notification in ipairs(damageNotifications) do
      if notification.healthLost > 0 and notification.sourceEntityId ~= notification.targetEntityId then
        triggerDrain(notification.healthLost * self.drainMultiplier)
        self.cooldownTimer = self.cooldown
        break
      end
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = self.cooldownTimer - dt
  end

  if self.triggerDrain then
    self.drainTimer = self.drainTimer - dt
    if self.drainTimer <= 0 then
        animator.setParticleEmitterActive("healing", false)
        self.triggerDrain = false
    end
  end
end

function triggerDrain(damage)
  self.triggerDrain = true
  self.drainTimer = self.visualDuration
  animator.setParticleEmitterActive("healing", true)
  status.modifyResource("health",damage)
end

function uninit()
  animator.setParticleEmitterActive("healing", true)
end
