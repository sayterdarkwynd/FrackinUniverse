require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

LanceAttack = WeaponAbility:new()

function LanceAttack:new(abilityConfig)
  local primary = config.getParameter("primaryAbility")
  return WeaponAbility.new(self, sb.jsonMerge(primary, abilityConfig))
end

function LanceAttack:init()
  self.cooldownTimer = 0
end

function LanceAttack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if not self.weapon.currentAbility
     and self.fireMode == "alt" 
     and self.cooldownTimer == 0
     and not world.lineTileCollision(mcontroller.position(), self:firePosition())
     and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.fire)
  end
end

function LanceAttack:fire()
  self.weapon:setStance(self.stances.fire)
  animator.setLightActive(self.weapon.elementalType.."flash", true)
  animator.playSound(self.weapon.elementalType.."lancefire")
  animator.setAnimationState("lance", "fire")

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("lance")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  animator.setLightActive(self.weapon.elementalType.."flash", false)
  self.cooldownTimer = self.cooldownTime
end

function LanceAttack:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function LanceAttack:uninit()
  
end
