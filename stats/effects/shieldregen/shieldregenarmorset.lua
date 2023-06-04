function init()
  self.shieldHealthRegen = status.stat("maxShield") * 1.3
  self.modifierGroup = effect.addStatModifierGroup({{stat = "shieldRegen", amount = self.shieldHealthRegen}})
  self.queryDamageSince = 0

end

function update(dt)
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  if #damageNotifications > 0 then
    self.pauseTimer = config.getParameter("pauseOnDamage", 0)
  end

  if status.stat("maxShield") <= 0 or (status.resource("shieldHealth") >= status.stat("maxShield")) then
    effect.expire()
  end
end
