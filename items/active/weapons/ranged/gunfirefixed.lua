require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/crits.lua"

-- Base gun fire ability, fixed. Includes more options and ways to customize a gun fire.

--[[New values this adds(none of these are required):
"loadupTime"(double) - time it takes to load up the gun. Shouldn't exist if you don't want a load up delay.
"burstCooldown"(double) - is used as a cooldown between bursts, instead of the normal weird calculation
"muzzleNoFlash"(boolean) - if true, there will be no muzzle, but there will be a sound after each shot though
"fireOffset"(Vec2F) - if exists, will make an offest FROM THE MUZZLE. Defaults to 0,0,
"runSlowWhileShooting"(bool) - if true(or exists), will make the player run slowly, when they shoot.
]]

GunFireFixed = WeaponAbility:new()

function GunFireFixed:init()
-- FU additions
  self.isReloader = config.getParameter("isReloader",0)  -- is this a shotgun style reload?
  
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  if self.loadupTime then
    self.loadupTimer = self.loadupTime
  else
    self.loadupTimer = 0
  end
  self.loadingUp = false

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFireFixed:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  if self.loadingUp then
  self.loadupTimer = math.max(0, self.loadupTimer - self.dt)
  end

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
  and not status.resourceLocked("energy")
  and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
  if self.runSlowWhileShooting then
    mcontroller.controlModifiers({groundMovementModifier = 0.5,
    speedModifier = 0.65,
    airJumpModifier = 0.80})
  end
  end
  if (not self.fireMode) and self.runSlowWhileShooting then
    mcontroller.clearControls()
  end
  if not (self.fireMode == (self.activatingFireMode or self.abilitySlot)
  and not status.resourceLocked("energy")
  and not world.lineTileCollision(mcontroller.position(), self:firePosition())) then
    if self.loadupTime then
      self.loadupTimer = self.loadupTime
    else
      self.loadupTimer = 0
    end
    self.loadingUp = false
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then


    if self.loadupTimer == 0 then
    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
    else
      if not self.loadingUp then
      self:setState(self.chargeup)
      end
    end
  end
end

function GunFireFixed:chargeup()
  self.loadingUp = true
  animator.playSound("charge")
end

function GunFireFixed:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
  self.isReloader = config.getParameter("isReloader",0)  
  if (self.isReloader) >= 1 then
    animator.playSound("cooldown") -- adds new sound to reload
  end  
end

function GunFireFixed:burst() -- burst auto should be a thing here
  self.weapon:setStance(self.stances.fire)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  if not self.burstCooldown then
    self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
  else
    self.cooldownTimer = self.burstCooldown
  end
end

function GunFireFixed:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function GunFireFixed:muzzleFlash()
  if not self.muzzleNoFlash then
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")

  animator.setLightActive("muzzleFlash", true)
  end
  animator.playSound("fire")
end

function GunFireFixed:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
    projectileId = world.spawnProjectile(
        projectileType,
        vec2.add((firePosition or self:firePosition()), (self.fireOffset or {0,0})),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function GunFireFixed:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFireFixed:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFireFixed:energyPerShot()
  if self.useEnergy == "nil" or self.useEnergy then -- key "useEnergy" defaults to true.
    return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
  else
    return 0
  end
end

function GunFireFixed:damagePerShot()
  return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end

function GunFireFixed:uninit()
end
