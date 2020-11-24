require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function setupAltAbility(altAbilityConfig, elementalType)
  local primary = config.getParameter("PrimaryAbility")
  local guidedRocket = GunFire:new(sb.jsonMerge(primary, altAbilityConfig), altAbilityConfig.stances)

  function guidedRocket:init()
    self:reset()

    self.rocketIds = {}
    self.cooldownTimer = self.fireTime
  end

  function guidedRocket:update(dt, fireMode, shiftHeld)
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.rocketIds = util.filter(self.rocketIds, world.entityExists)
    for _,rocketId in pairs(self.rocketIds) do
      world.callScriptedEntity(rocketId, "setTarget", activeItem.ownerAimPosition())
    end

    self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

    if self.fireMode == "alt"
       and not self.weapon.currentAbility
       and self.cooldownTimer == 0
       and not world.lineTileCollision(mcontroller.position(), self:firePosition())
       and status.overConsumeResource("energy", self:energyPerShot())  then
      self:setState(self.fire)
    end
  end

  function guidedRocket:fire()
    table.insert(self.rocketIds, self:fireProjectile())

    animator.setAnimationState("firing", "fire")
    animator.burstParticleEmitter("altMuzzleFlash")
    animator.playSound(self.weapon.elementalType.."Guided")

    self.cooldownTimer = self.fireTime
    self:setState(self.cooldown)
  end

  function guidedRocket:reset()
  end

  return guidedRocket
end
