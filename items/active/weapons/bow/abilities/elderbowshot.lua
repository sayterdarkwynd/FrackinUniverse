require "/scripts/vec2.lua"

-- Bow primary ability
BowShot = WeaponAbility:new()

function BowShot:init()
  storage.projectiles = storage.projectiles or {}

  self.critChance = config.getParameter("critChance", 0)
  self.critBonus = config.getParameter("critBonus", 0)
  self.energyPerShot = self.energyPerShot or 0

  self.drawTime = 0
  self.cooldownTimer = self.cooldownTime

  self:reset()

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end


  -- *******************************************************
  -- FU Crit Damage Script

function BowShot:setCritDamage(damage)
	if not self.critChance then
		self.critChance = config.getParameter("critChance", 0)
	end
	if not self.critBonus then
		self.critBonus = config.getParameter("critBonus", 0)
	end
     -- check their equipped weapon
     -- Primary hand, or single-hand equip
     local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
     --used for checking dual-wield setups
     local opposedhandHeldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand() == "primary" and "alt" or "primary")
     local weaponModifier = config.getParameter("critChance",0)

  if heldItem then
      if root.itemHasTag(heldItem, "bow") then
        self.critChance = 0.25 + weaponModifier
      elseif root.itemHasTag(heldItem, "crossbow") then
        self.critChance = 0.25 + weaponModifier
      end
  end
    --sb.logInfo("crit chance base="..self.critChance)

  --critBonus is bonus damage done with crits
  self.critBonus = ( ( ( (status.stat("critBonus") + config.getParameter("critBonus",0)) * self.critChance ) /100 ) /2 ) or 0
  -- this next modifier only applies if they have a multiply item equipped
  self.critChance = (self.critChance  + config.getParameter("critChanceMultiplier",0)+ status.stat("critChanceMultiplier",0) + status.stat("critChance",0))
  -- random dice roll. I've heavily lowered the chances, as it was far too high by nature of the random roll.
  self.critRoll = math.random(200)

  --apply the crit

  local crit = self.critRoll <= self.critChance
    --sb.logInfo("crit roll="..self.critRoll)
  damage = crit and (damage*2) + self.critBonus or damage

  if crit then
    if heldItem then
      -- exclude mining lasers
      if not root.itemHasTag(heldItem, "mininggun") then
        status.addEphemeralEffect("crithit", 0.3, activeItem.ownerEntityId())
      end
    end
  end

  return damage
end
  -- *******************************************************



function BowShot:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.updateProjectiles()

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
    local projectileId = world.spawnProjectile(
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

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", nil)
    end

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

function BowShot:updateProjectiles()
  --local aimPosition = activeItem.ownerAimPosition()
  local newProjectiles = {}
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", nil)
      if projectileResponse:finished() then
        local newIds = projectileResponse:result()
        if type(newIds) ~= "table" then
          newIds = {newIds}
        end
        for _, newId in pairs(newIds) do
          table.insert(newProjectiles, newId)
        end
      end
    end
  end
  storage.projectiles = newProjectiles
end
