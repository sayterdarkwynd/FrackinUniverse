require "/scripts/vec2.lua"

ZenShot = WeaponAbility:new()

function ZenShot:init()
  self.energyPerShot = self.energyPerShot or 0

  self.drawTime = 0
  self.cooldownTimer = self.cooldownTime

  self.projectileParameters = self.projectileParameters or {}

  local projectileConfig = root.projectileConfig(self.projectileType)
  self.projectileParameters.speed = self.projectileParameters.speed or projectileConfig.speed
  self.projectileParameters.power = self.projectileParameters.power or projectileConfig.power
  self.projectileParameters.power = self.projectileParameters.power * self.weapon.damageLevelMultiplier

  self.projectileParameters.periodicActions = {
    {
      time = self.splitDelay,
      ["repeat"] = false,
      action = "projectile",
      type = self.projectileType,
      angleAdjust = -25,
      inheritDamageFactor = 0.5,
      inheritSpeedFactor = 0.7
    },
    {
      time = self.splitDelay,
      ["repeat"] = false,
      action = "projectile",
      type = self.projectileType,
      angleAdjust = -15,
      inheritDamageFactor = 0.5,
      inheritSpeedFactor = 0.8
    },
    {
      time = self.splitDelay,
      ["repeat"] = false,
      action = "projectile",
      type = self.projectileType,
      angleAdjust = 0,
      inheritDamageFactor = 0.35,
      inheritSpeedFactor = 1.0
    }
  }

  self.projectileGravityMultiplier = root.projectileGravityMultiplier(self.projectileType)

end

function ZenShot:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyPerShot == 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
end

function ZenShot:uninit()
  self:reset()
end

function ZenShot:reset()
  animator.setGlobalTag("drawFrame", "0")
  -- self.weapon:setStance(self.stances.idle)
end

function ZenShot:windup()
  self.weapon:setStance(self.stances.windup)

  activeItem.emote("sleep")

  util.wait(self.stances.windup.duration, function()

    end)

  self:setState(self.draw)
end

function ZenShot:draw()
  self.weapon:setStance(self.stances.draw)

  animator.playSound("draw")

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    if self.walkWhileFiring then mcontroller.controlModifiers({runningSuppressed = true}) end

    self.drawTime = self.drawTime + self.dt

    local drawFrame = math.floor(root.evalFunction(self.drawFrameSelector, self.drawTime))
    animator.setGlobalTag("drawFrame", drawFrame)
    self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

    local aimVec = self:aimVector()
    aimVec[1] = aimVec[1] * self.weapon.aimDirection

    self.weapon.aimAngle = (4 * self.weapon.aimAngle + vec2.angle(aimVec)) / 5

    coroutine.yield()
  end

  self:setState(self.fire)
end

function ZenShot:fire()
  self.weapon:setStance(self.stances.fire)

  animator.stopAllSounds("draw")
  animator.setGlobalTag("drawFrame", "0")

  if not world.pointTileCollision(self:firePosition()) and status.overConsumeResource("energy", self.energyPerShot) then
    local params = copy(self.projectileParameters)
    params.powerMultiplier = activeItem.ownerPowerMultiplier()
    params.power = params.power * root.evalFunction(self.drawPowerMultiplier, self.drawTime)
    params.speed = params.speed * root.evalFunction(self.drawSpeedMultiplier, self.drawTime)

    world.spawnProjectile(
        self.projectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(),
        false,
        params
      )

    animator.playSound("release")

    self.drawTime = 0

    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.cooldownTime
end

function ZenShot:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

function ZenShot:idealAimVector()
  local targetOffset = world.distance(activeItem.ownerAimPosition(), self:firePosition())
  return util.aimVector(targetOffset, self.projectileParameters.speed, self.projectileGravityMultiplier, true)
end

function ZenShot:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end
