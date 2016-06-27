bubbleShieldSpecial = {
  active = false,
  health = 0,
  duration = 0
}

function bubbleShieldSpecial.onDamage(args)
  if sourceId ~= 0 then
  end
end

function bubbleShieldSpecial.onUpdate(dt)
  --Keep the shield up if it's up, activate if the cooldown is off
  if status.resourcePositive("shieldHealth") or (self.skillCooldownTimers["bubbleShieldSpecial"] <= 0 and hasTarget()) then
    bubbleShieldSpecial.activateShield()
  end

  if bubbleShieldSpecial.duration <= 0 and status.resourcePositive("shieldHealth") then
    bubbleShieldSpecial.deactivateShield()
  end
  bubbleShieldSpecial.duration = bubbleShieldSpecial.duration - dt
end

function bubbleShieldSpecial.activateShield()
  if self.skillCooldownTimers["bubbleShieldSpecial"] <= 0 then
    bubbleShieldSpecial.duration = entity.configParameter("bubbleShieldSpecial.shieldTime")
  end

  status.addEphemeralEffect("bubbleshield")
  self.skillCooldownTimers["bubbleShieldSpecial"] = entity.configParameter("bubbleShieldSpecial.cooldownTime")
end

function bubbleShieldSpecial.deactivateShield()
  status.removeEphemeralEffect("bubbleshield")
  if self.skillCooldownTimers["bubbleShieldSpecial"] <= 0 then
    self.skillCooldownTimers["bubbleShieldSpecial"] = entity.configParameter("bubbleShieldSpecial.cooldownTime")
  end
end
