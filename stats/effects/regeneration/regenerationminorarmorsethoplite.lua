function init()
  self.shieldHealthRegen = status.stat("maxShield") * 1.3
  self.modifierGroup = effect.addStatModifierGroup({{stat = "shieldRegen", amount = self.shieldHealthRegen}})
  self.queryDamageSince = 0
  script.setUpdateDelta(5)
end

function update(dt)
  self.healingRate = 0.000005
  status.modifyResourcePercentage("health", self.healingRate * 1.0)
  
  local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
  self.queryDamageSince = nextStep
  if #damageNotifications > 0 then
    self.pauseTimer = config.getParameter("pauseOnDamage", 0)
  end

  if status.stat("maxShield") <= 0 or (status.resource("shieldHealth") >= status.stat("maxShield")) then
    effect.expire()
  end
  
end

function uninit()
  
end