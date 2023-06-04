require "/items/active/weapons/melee/meleeslash.lua"

-- Spear stab attack
-- Extends normal melee attack and adds a hold state
DrillSpearStab = MeleeSlash:new()

function DrillSpearStab:init()
  MeleeSlash.init(self)

  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end

function DrillSpearStab:fire()
  animator.setAnimationState("drill", "active1")

  MeleeSlash.fire(self)

  animator.setAnimationState("drill", "idle")

  if self.fireMode == "primary" and self.allowHold ~= false then
    self:setState(self.hold)
  end
end

function DrillSpearStab:hold()
  self.weapon:setStance(self.stances.hold)
  self.weapon:updateAim()

  animator.setAnimationState("drill", "active1")

  while self.fireMode == "primary" do
    local damageArea = partDamageArea("spear")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    coroutine.yield()
  end

  animator.setAnimationState("drill", "idle")

  self.cooldownTimer = self:cooldownTime()
end
