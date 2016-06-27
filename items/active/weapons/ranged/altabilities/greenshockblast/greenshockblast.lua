require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function setupAltAbility(altAbilityConfig)
  local burstShot = WeaponAbility:new(altAbilityConfig, altAbilityConfig.stances)

  function burstShot:init()
    self:reset()

    self.cooldownTimer = 0
  end

  function burstShot:update(dt, fireMode, shiftHeld)
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

    if self.weapon.currentAbility == nil
      and self.fireMode == "alt"
      and self.cooldownTimer == 0
      and not world.lineTileCollision(mcontroller.position(), self:firePosition())
      and status.overConsumeResource("energy", self.energyUsage) then

      self:setState(self.fire)
    end
  end

  function burstShot:fire()
    self.weapon:setStance(self.stances.fire)
    self.weapon:updateAim()

    animator.setAnimationState("burstShotFire", "fire")
    animator.burstParticleEmitter("burstShotSmoke")
    animator.playSound("burstshot")

    util.wait(self.stances.fire.duration, function()
      local damageArea = partDamageArea("burstShotExplosion")
      self.weapon:setDamage(self.damageConfig, damageArea)
    end)

    self.cooldownTimer = self.cooldownTime
  end

  function burstShot:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
  end

  function burstShot:reset()
    animator.setAnimationState("burstShotFire", "idle")
  end

  function burstShot:uninit()
    self:reset()
  end

  return burstShot
end
