shieldSpecial = {
  activate = false,
  health = 0,
  duration = 0,
  regenCooldown = 0,
  lastShieldHealth = 0
}

function shieldSpecial.onDamage(args)
  if sourceId ~= 0 and hasTarget() and shieldSpecial.activate then
    shieldSpecial.activateShield()
  end
end

function shieldSpecial.onUpdate(dt)
  if not hasTarget() then
    shieldSpecial.deactivateShield()
    return true
  end

  --Set to activate on next damage
  if self.skillCooldownTimers["shieldSpecial"] <= 0 then
    shieldSpecial.activate = true
  end

  --Keep the shield up if it's up
  if status.resourcePositive("shieldHealth") then
    shieldSpecial.activateShield()
  end

  --Regenerate shield when we haven't taken damage for a while
  if status.resource("shieldHealth") < shieldSpecial.lastShieldHealth then
    status.removeEphemeralEffect("shieldregen")
    shieldSpecial.regenCooldown = config.getParameter("shieldSpecial.regenCooldown")
  elseif shieldSpecial.regenCooldown <= 0 and status.resource("shieldHealth") < status.stat("maxShield") then
    status.addEphemeralEffect("shieldregen")
  end
  shieldSpecial.regenCooldown = shieldSpecial.regenCooldown - dt

  if shieldSpecial.duration <= 0 then
    shieldSpecial.deactivateShield()
  end
  shieldSpecial.duration = shieldSpecial.duration - dt

  shieldSpecial.lastShieldHealth = status.resource("shieldHealth")
end

function shieldSpecial.activateShield()
  if shieldSpecial.activate then
    shieldSpecial.duration = config.getParameter("shieldSpecial.shieldTime")
  end

  shieldSpecial.activate = false
  status.addEphemeralEffect("staticshield")
  self.skillCooldownTimers["shieldSpecial"] = config.getParameter("shieldSpecial.cooldownTime")
end

function shieldSpecial.deactivateShield()
  status.removeEphemeralEffect("staticshield")
  status.removeEphemeralEffect("shieldregen")
  if self.skillCooldownTimers["shieldSpecial"] <= 0 then
    self.skillCooldownTimers["shieldSpecial"] = config.getParameter("shieldSpecial.cooldownTime")
  end
end
