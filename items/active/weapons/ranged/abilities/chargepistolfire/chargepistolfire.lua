require "/scripts/util.lua"
require "/scripts/interp.lua"

ChargeFire = WeaponAbility:new()

function ChargeFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.chargeFireTime
  self.chargeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function ChargeFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and self.cooldownTimer == 0
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and not status.resourceLocked("energy") then

    self:setState(self.charge)
  end
end

function ChargeFire:charge()
  self.weapon:setStance(self.stances.charge)

  animator.setAnimationState("firing", "charge")

  self.chargeTimer = 0

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    self.chargeTimer = self.chargeTimer + self.dt

    coroutine.yield()
  end

  self:setState(self.fire)
end

function ChargeFire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.setAnimationState("firing", "fire")

  self:fireProjectile()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  if self.chargeTimer >= self.chargeTime then
    self.cooldownTimer = self.chargeFireTime
  else
    self.cooldownTimer = self.fireTime
  end

  self:setState(self.cooldown, self.cooldownTimer)
end

function ChargeFire:cooldown(duration)
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / duration))
  end)
end

function ChargeFire:fireProjectile()
  local pConfig = self.chargeTimer >= self.chargeTime and self.chargedProjectile or self.projectile

  local params = copy(pConfig.parameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()

  for i = 1, pConfig.count or 1 do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        pConfig.type,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(self.inaccuracy),
        false,
        params
      )
  end
end

function ChargeFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function ChargeFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

-- function ChargeFire:energyPerShot()
--   return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
-- end

-- function ChargeFire:damagePerShot()
--   return (self.baseDamage or (self.baseDps * self.fireTime)) * config.getParameter("damageLevelMultiplier") / self.projectileCount
-- end

function ChargeFire:uninit()
end
