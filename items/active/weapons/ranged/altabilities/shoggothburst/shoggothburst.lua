require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function setupAltAbility(altAbilityConfig, elementalType)
  local primary = config.getParameter("PrimaryAbility")
  local rocketBurst = GunFire:new(sb.jsonMerge(primary, altAbilityConfig), altAbilityConfig.stances)

  function rocketBurst:init()
    self.cooldownTimer = self.fireTime
  end

  function rocketBurst:update(dt, fireMode, shiftHeld)
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

    if self.fireMode == "alt"
      and not self.weapon.currentAbility
      and self.cooldownTimer == 0
      and not status.resourceLocked("energy")
      and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
      
      self:setState(self.burst)
    end
  end

  function rocketBurst:fireProjectile(...)
    local projectileId = GunFire.fireProjectile(self, ...)
    world.callScriptedEntity(projectileId, "setApproach", self:aimVector(0))
  end

  function rocketBurst:muzzleFlash()
    animator.burstParticleEmitter("altMuzzleFlash", true)
    animator.playSound("altFire")
  end

  return rocketBurst
end