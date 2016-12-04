require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Flurry = WeaponAbility:new()

function Flurry:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
end

function Flurry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and self.fireMode == "alt" then
    
    self:setState(self.swing)
  end
end

function Flurry:swing()
  local cooldownTime = self.maxCooldownTime
  local currentRotationOffset = 1
  while self.fireMode == "alt" do
    if not status.overConsumeResource("energy", self.energyUsage) then break end

    self.weapon:setStance(self.stances.swing)
    self.weapon.relativeWeaponRotation = util.toRadians(self.stances.swing.weaponRotation + self.cycleRotationOffsets[currentRotationOffset])
    self.weapon.relativeArmRotation = util.toRadians(self.stances.swing.armRotation + self.cycleRotationOffsets[currentRotationOffset])
    self.weapon:updateAim()

    animator.setAnimationState("swoosh", "fire")
    animator.playSound("flurry")
    util.wait(self.stances.swing.duration, function(dt)
      local damageArea = partDamageArea("swoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)

    -- allow changing aim during cooldown
    self.weapon:setStance(self.stances.idle)
    util.wait(cooldownTime - self.stances.swing.duration, function(dt)
      return self.fireMode ~= "alt"
    end)

    cooldownTime = math.max(self.minCooldownTime, cooldownTime - self.cooldownSwingReduction)

    currentRotationOffset = currentRotationOffset + 1
    if currentRotationOffset > #self.cycleRotationOffsets then
      currentRotationOffset = 1
    end
  end
  self.cooldownTimer = self.cooldownTime
end

function Flurry:reset()
end

function Flurry:uninit()
  self:reset()
end
