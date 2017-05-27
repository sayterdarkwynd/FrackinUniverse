require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Charge = WeaponAbility:new()

function Charge:init()
  self:reset()
end

function Charge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and not status.resourceLocked("energy") then
    self:setState(self.charge)
  end
end

function Charge:charge()
  self.weapon:setStance(self.stances.charge)
  self.weapon:updateAim()

  animator.setAnimationState("dashSwoosh", "charge")

  local chargeTimer = 0
  local chargeLevel = 0
  while self.fireMode == "alt" and (chargeLevel == self.chargeLevels or status.overConsumeResource("energy", (self.maxEnergyUsage / self.chargeTime) * self.dt)) do
    chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)
    chargeLevel = self:setChargeLevel(chargeTimer, chargeLevel)
    coroutine.yield()
  end

  if chargeTimer > self.minChargeTime then
    self:setState(self.dash, chargeTimer / self.chargeTime, chargeLevel)
  end
end

function Charge:dash(charge,level)
  self.weapon:setStance(self.stances.dash)
  self.weapon:updateAim()

  self:setLightning(3, self.dashLightning[1], self.dashLightning[2], self.dashLightning[3], self.dashLightning[4], 8)

  animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")
  animator.setAnimationState("swoosh", "fire")
  animator.setAnimationState("dashSwoosh", "full")
  animator.playSound("fire")

  local uuid = sb.makeUuid()
  if level == 4 then
    local position = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("blade", "projectileSource")))
    local aimDirection = {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}
    local params = copy(self.projectileParameters)
    local projectileId = world.spawnProjectile(self.projectileType,position,activeItem.ownerEntityId(),aimDirection,true,params)
    local time = self.maxDashTime * charge
    world.sendEntityMessage(projectileId, "timetolive", time)
  end

  util.wait(self.maxDashTime * charge, function(dt)
    local aimDirection = {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}
    mcontroller.controlApproachVelocity(vec2.mul(aimDirection, self.dashMaxSpeed), self.dashControlForce)
    mcontroller.controlParameters({
      airFriction = 0,
      groundFriction = 0,
      liquidFriction = 0,
      gravityEnabled = false
    })

    local damageArea = partDamageArea("dashSwoosh")
    self.damageConfig.baseDamage = self.baseDps * self.chargeTime * charge
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  -- freeze in mid air for a short amount of time
  util.wait(self.freezeTime, function(dt)
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setVelocity({0,0})
  end)
end

function Charge:reset()
  activeItem.setScriptedAnimationParameter("lightning", {})
  animator.setAnimationState("dashSwoosh", "idle")
end

function Charge:uninit()
  self:reset()
  if self.weapon.currentState == self.dash then
    mcontroller.setVelocity({0,0})
  end
end

function Charge:setChargeLevel(chargeTimer, currentLevel)
  local level = math.min(self.chargeLevels, math.ceil(chargeTimer / self.chargeTime * self.chargeLevels))
  if currentLevel < level then
    local lightningCharge = self.lightningChargeLevels[level]
    self:setLightning(3, lightningCharge[1], lightningCharge[2], lightningCharge[3], lightningCharge[4], 2.75 + level)
  end
  return level
end

function Charge:setLightning(amount, width, forks, branching, color, length)
  local lightning = {}
  for i = 1, amount do
    local bolt = {
      minDisplacement = 0.225,
      forks = forks,
      forkAngleRange = 0.90,
      width = width,
      color = color,
      endPointDisplacement = -branching + (i * 2 * branching)
    }
    bolt.itemStartPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0}), self.weapon.relativeWeaponRotation)
    bolt.itemEndPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0 - length}), self.weapon.relativeWeaponRotation)
    bolt.displacement = vec2.mag(vec2.sub(bolt.itemEndPosition, bolt.itemStartPosition)) / 4
    table.insert(lightning, bolt)
  end
  activeItem.setScriptedAnimationParameter("lightning", lightning)
end
