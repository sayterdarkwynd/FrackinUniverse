require "/scripts/vec2.lua"

-- Bow primary ability
BowShot = WeaponAbility:new()

function BowShot:init()
  self.energyPerShot = self.energyPerShot or 0

  self.drawTime = 0
  self.cooldownTimer = self.cooldownTime

  self:reset()

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end



function BowShot:setCritDamage(damage)
  -- *******************************************************
  -- FU Crit Damage Script
  self.critChance = config.getParameter("critChance") or 1
  self.critBonus = config.getParameter("critBonus") or 0
  -- *******************************************************

  -- *************************
  -- Setting base crit rates
  
  -- **** check primary hand
     local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
     if heldItem then
	     if root.itemHasTag(heldItem, "bow") then self.critChance = 10 end
	     if root.itemHasTag(heldItem, "crossbow") then self.critChance = 10 end
     end
  
  self.critChance = self.critChance * ( 1 + status.stat("critChanceMultiplier") )
  local crit = math.random(100) <= self.critChance
  local critDamage = crit and (damage*2) + self.critBonus or damage
  return critDamage  
end



function BowShot:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyPerShot == 0 or not status.resourceLocked("energy")) then
    self:setState(self.draw)
  end
end

function BowShot:uninit()
  self:reset()
end

function BowShot:reset()
  animator.setGlobalTag("drawFrame", "0")
  self.weapon:setStance(self.stances.idle)
end

function BowShot:draw()
  self.weapon:setStance(self.stances.draw)

  animator.playSound("draw")

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    if self.walkWhileFiring then mcontroller.controlModifiers({runningSuppressed = true}) end

    self.drawTime = self.drawTime + self.dt

    local drawFrame = math.floor(root.evalFunction(self.drawFrameSelector, self.drawTime))
    animator.setGlobalTag("drawFrame", drawFrame)
    self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

    coroutine.yield()
  end

  self:setState(self.fire)
end

function BowShot:fire()
  self.weapon:setStance(self.stances.fire)

  animator.stopAllSounds("draw")
  animator.setGlobalTag("drawFrame", "0")

  if not world.pointTileCollision(self:firePosition()) and status.overConsumeResource("energy", self.energyPerShot) then
    world.spawnProjectile(
        self:perfectTiming() and self.powerProjectileType or self.projectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(),
        false,
        self:currentProjectileParameters()
      )

    if self:perfectTiming() then
      animator.playSound("perfectRelease")
    else
      animator.playSound("release")
    end

    self.drawTime = 0

    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.cooldownTime
end

function BowShot:perfectTiming()
  return self.drawTime > self.powerProjectileTime[1] and self.drawTime < self.powerProjectileTime[2]
end

function BowShot:currentProjectileParameters()
  local projectileParameters = copy(self.projectileParameters or {})
  local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.projectileType)
  projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
  projectileParameters.speed = projectileParameters.speed * root.evalFunction(self.drawSpeedMultiplier, self.drawTime)
  projectileParameters.power = projectileParameters.power or projectileConfig.power
  --projectileParameters.power = projectileParameters.power* self.weapon.damageLevelMultiplier* root.evalFunction(self.drawPowerMultiplier, self.drawTime) + BowShot:setCritDamage(damage)
  projectileParameters.power = BowShot:setCritDamage( projectileParameters.power* self.weapon.damageLevelMultiplier* root.evalFunction(self.drawPowerMultiplier, self.drawTime))
  projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()

  return projectileParameters
end

function BowShot:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

function BowShot:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

