--Modified bow shot ability that drains energy while drawing and holding, with configurable drain rates. Has an animation state for when arrows have been loosed
require "/scripts/vec2.lua"

-- Bow primary ability
NebArrowRain = WeaponAbility:new()

function NebArrowRain:init()
  self.energyPerShot = self.energyPerShot or 0
  animator.setGlobalTag("directives", config.getParameter("directives", ""))
  self.paletteSwaps = config.getParameter("paletteSwaps")
  self.elementalType = config.getParameter("elementalType")
  self.arrowVariant = config.getParameter("animationParts")
  self.drawTimer = 0
  animator.setAnimationState("bow", "idle")
  self.cooldownTimer = 0
  self.clusterProjectileType = self.altProjectileType
  self.aimOutOfReach = false
  self.aimTypeSwitchTimer = 0
  self.actionOnReapParameters = {}
  self:reset()
  self.projectileParameters = self.projectileParameters or {}
  self.projectileParameters.timeToLive = self.timeUntilSplit + (self.timeUntilSplit/5)
  self.projectileGravityMultiplier = self.projectileMovementParameters.gravityMultiplier or root.projectileGravityMultiplier(self.powerProjectileType or self.altProjectileType)
  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function NebArrowRain:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  world.debugPoint(self:firePosition(), "red")

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.drawTimer > 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
end

function NebArrowRain:uninit()
  self:reset()
end

function NebArrowRain:reset()
  animator.setGlobalTag("drawFrame", "0")
  animator.setAnimationState("bow", "idle")
  animator.stopAllSounds("draw")
  animator.stopAllSounds("ready")
  self.weapon:setStance(self.stances.idle)
end

function NebArrowRain:windup()
  self.weapon:setStance(self.stances.windup)
  activeItem.emote("sleep")
  util.wait(self.stances.windup.duration)
  self:setState(self.draw)
end

function NebArrowRain:draw()
  self.weapon:setStance(self.stances.draw)
  animator.playSound("draw", -1)
  local readySoundPlayed = false

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") do
    if self.walkWhileFiring then
		mcontroller.controlModifiers({runningSuppressed = true})
    end
    self.drawTimer = self.drawTimer + self.dt
    local drawFrame = math.min(#self.drawArmFrames - 2, math.floor(self.drawTimer / self.drawTime * (#self.drawArmFrames - 1)))

		--If not yet fully drawn, drain energy quickly
		if self.drawTimer < self.drawTime then
			status.overConsumeResource("energy", self.energyPerShot / self.drawTime * self.dt)

		--If fully drawn and at peak power, prevent energy regen and set the drawFrame to power charged
		elseif self.drawTimer > self.drawTime and self.drawTimer <= (self.drawTime + (self.powerProjectileTime or 0)) then
			status.setResourcePercentage("energyRegenBlock", 0.6)
			drawFrame = #self.drawArmFrames - 1
			if self.drainEnergyWhilePowerful then
				status.overConsumeResource("energy", self.holdEnergyUsage * self.dt) --Optionally drain energy while at max power level
			end

		--If drawn beyond power peak levels, drain energy slowly
		elseif self.drawTimer > (self.drawTime + (self.powerProjectileTime or 0)) then
			status.overConsumeResource("energy", self.holdEnergyUsage * self.dt)
		end
		--If the bow is almost fully drawn, stop the draw sound and play the ready sound
		--Do this slightly before the draw is ready so the player can release when they hear the sound
		--This way, the sound plays at the same moment in the draw phase for every bow regardless of draw time
		if self.drawTimer >= (self.drawTime - 0.15) then
			animator.stopAllSounds("draw")
			if not readySoundPlayed then
				animator.playSound("ready")
				readySoundPlayed = true
			end
		end

    --Code for calculating which cursor to use
    if not self.hasChargedCursor then
      local cursorFrame = math.max(math.ceil(self.drawTimer * #self.cursorFrames), 1)
      activeItem.setCursor(self.cursorFrames[cursorFrame])
	  if cursorFrame == #self.cursorFrames then
	    self.hasChargedCursor = true
	  end
    else
      activeItem.setCursor(self.cursorFrames[#self.cursorFrames])
    end

    local aimVec = self:idealAimVector()
    if self.aimOutOfReach or self.aimTypeSwitchTimer > 0 then
	  local aimAngle = activeItem.aimAngleAndDirection(self.weapon.aimOffset, activeItem.ownerAimPosition())
	  self.weapon.aimAngle = aimAngle
	  self.weapon:updateAim()
	  world.debugLine(self:firePosition(), vec2.add(self:firePosition(), vec2.mul(vec2.norm(self:idealAimVector()), 3)), "yellow")
    else
	  aimVec[1] = aimVec[1] * self.weapon.aimDirection
          self.weapon.aimAngle = (4 * self.weapon.aimAngle + vec2.angle(aimVec)) / 5
	  world.debugLine(self:firePosition(), vec2.add(self:firePosition(), vec2.mul(vec2.norm(self:idealAimVector()), 3)), "green")
    end

    animator.setGlobalTag("drawFrame", drawFrame)

    if drawFrame == 5 then --or whatever the frame is
      animator.setGlobalTag("directives", "?fade=FFFFFFFF=0.1")
    else
      animator.setGlobalTag("directives", "")
    end
    self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]
    world.debugText(sb.printJson(self:currentProjectileParameters(), 1), mcontroller.position(), "yellow")
    coroutine.yield()
  end

  animator.stopAllSounds("draw")
  if self.drawTimer < self.drawTime then
    self:setState(self.reset)
  else
    self:setState(self.fire)
  end
end

function NebArrowRain:fire()
  self.hasChargedCursor = false
  activeItem.setCursor(self.cursorFrames[1])
  self.weapon:setStance(self.stances.fire)

  animator.setGlobalTag("drawFrame", "0")
  animator.setGlobalTag("directives", "")
  animator.stopAllSounds("ready")

  if not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    local projectileParameters = copy(self:perfectTiming() and self.powerProjectileParameters or self.projectileParameters or {})
    if self.drawTimer > (self.drawTime + (self.powerProjectileTime or 0)) then
	  if self.elementalType ~= "physical" then
	    self.projectileParameters.damageKind = self.elementalType .. "bow"
      end
	  self.projectileParameters.periodicActions = {
        {
          time = 0,
          action = "projectile",
          type = self.elementalType .. "arrowenergy",
          angleAdjust = 0,
	      config = {timeToLive = 0},
          inheritDamageFactor = 0.0,
          inheritSpeedFactor = 1
        }
      }
    end

	--Calculate projectile speed based on draw time and projectile parameters
    projectileParameters.speed = projectileParameters.speed * math.min(1, (self.drawTimer / self.drawTime))
    projectileParameters.processing = self.paletteSwaps

	--Calculate projectile power based on draw time and projectile parameters
	local drawTimeMultiplier = self.staticDamageMultiplier or math.min(1, (self.drawTimer / self.drawTime))
    projectileParameters.power = projectileParameters.power
      * self.weapon.damageLevelMultiplier
      * drawTimeMultiplier
    projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()

    projectileParameters.actionOnReap = {}
	projectileParameters.timeToLive = self.timeUntilSplit + (self.timeUntilSplit/2)
    local angles = self:unpack(self:splitAngle(-1 * mcontroller.facingDirection() * self.arrowSplitAngle + math.pi * self.splitCount, -1 * mcontroller.facingDirection() * self.arrowSplitAngle - math.pi * self.splitCount, self.splitCount))
	for _, angle in ipairs(angles) do
		table.insert(projectileParameters.actionOnReap, {
		  time = self.timeUntilSplit,
		  ["repeat"] = false,
		  action = "projectile",
		  type = self.altProjectileType,
		  config = {actionOnReap = self.actionOnReapParameters, processing = self.paletteSwaps},
		  angleAdjust = angle,
		  inheritDamageFactor = 1.0,
		  inheritSpeedFactor = math.random() * (self.maxProjectileSpeedInherit - self.minProjectileSpeedInherit) + self.minProjectileSpeedInherit
		})
	end

	--Spawn the projectile using the calculated parameters
    for _ = 1, (self.projectileCount or 1) do
      local projectileId = world.spawnProjectile(
        self.altProjectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:idealAimVector(),
        false,
        projectileParameters
      )

	  world.callScriptedEntity(projectileId, "setMovementParameters", self.projectileMovementParameters)
	  if self:perfectTiming() then
		animator.playSound("perfectRelease")
	  else
		animator.playSound("release")
	  end
	end
	animator.setAnimationState("bow", "loosed")
    self.drawTimer = 0
    util.wait(self.stances.fire.duration)
  else
    animator.setGlobalTag("drawFrame", "0")
  end
  self.projectileParameters.periodicActions = nil
  self.cooldownTimer = self.cooldownTime
  animator.setGlobalTag("directives", "")
end

--Call this to check if the bow was released at the perfect moment. Bows can be configured to not use perfect timing mechanics
function NebArrowRain:perfectTiming()
  if self.powerProjectileTime then
	return self.drawTimer > self.drawTime and self.drawTimer < (self.drawTime + self.powerProjectileTime)
  else
	return false
  end
end

function NebArrowRain:currentProjectileParameters()
  local arrowVariant = self.arrowVariant.arrow:match("(%d+)%.png")
  --Set projectile parameters based on draw power level
  local projectileParameters = copy(self:perfectTiming() and self.powerProjectileParameters or self.projectileParameters or {})
  --Load the root projectile config based on draw power level
  local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.altProjectileType)

  local speedMultiplier = 1.0
  if self.minMaxSpeedMultiplier then
	speedMultiplier = math.random(self.minMaxSpeedMultiplier[1] * 100, self.minMaxSpeedMultiplier[2] * 100) / 100
  end

  --Calculate projectile speed based on draw time and projectile parameters
  projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
  projectileParameters.speed = projectileParameters.speed * math.min(1, (self.drawTimer / self.drawTime)) * speedMultiplier

  projectileParameters.processing = self.paletteSwaps

  if self.altProjectileType == "rngbouncingarrow" then
    self.projectileParameters.actionOnReap = nil
  else
    self.actionOnReapParameters = {
      {
        action = "projectile",
        type = "arrow" .. arrowVariant .. "sticking",
        angleAdjust = 0,
	    config = {processing = self.paletteSwaps},
        inheritDamageFactor = 0.1,
        inheritSpeedFactor = 0.6
      }
    }
	self.projectileParameters.actionOnReap = self.actionOnReapParameters
  end

  --Bonus damage calculation for quiver users
  local damageBonus = 1.0
  if self.useQuiverDamageBonus == true and status.statPositive("RNGdamageQuiver") then
	damageBonus = status.stat("RNGdamageQuiver")
  end

  --Calculate projectile power based on draw time and projectile parameters
  local drawTimeMultiplier = self.staticDamageMultiplier or math.min(1, (self.drawTimer / self.drawTime))
  projectileParameters.power = projectileParameters.power or projectileConfig.power
  projectileParameters.power = projectileParameters.power
    * self.drawTime
	* self.weapon.damageLevelMultiplier
	* drawTimeMultiplier
	* (self.dynamicDamageMultiplier or 1)
	* damageBonus
	* (mcontroller.onGround() and 1 or self.airborneBonus)
	/ (self.projectileCount or 1)
  projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()

  return projectileParameters
end

function NebArrowRain:idealAimVector()
  --local targetOffset = world.distance(activeItem.ownerAimPosition(), self:firePosition())
  --local aimVec = util.aimVector(targetOffset, self.projectileParameters.speed, self.projectileGravityMultiplier, true)
  ----local aimVector = vec2.rotate(aimVec, self.weapon.aimAngle + 0, 0)
  --aimVec[1] = aimVec[1] * self.weapon.aimDirection
  --return aimVec

  self.aimOutOfReach = true
  --If we are at a zero G position, use regular aiming instead of arc-adjusted aiming
  if mcontroller.zeroG() then
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	self.aimTypeSwitchTimer = 0.1 --Hold the last aiming type for a brief moment to smooth transitions
	return aimVector
  else
	local targetOffset = world.distance(activeItem.ownerAimPosition(), self:firePosition())

	--Code taken from util.lua to determine when the aim position is out of range
	local x = targetOffset[1]
	local y = targetOffset[2]
	local g = self.projectileGravityMultiplier * world.gravity(mcontroller.position())
	local v = self.projectileParameters.speed
	if g < 0 then
	  g = -g
	  y = -y
	end
	local term1 = v^4 - (g * ((g * x * x) + (2 * y * v * v)))

	if term1 > 0 then
	  self.aimOutOfReach = false
	  return util.aimVector(targetOffset, self.projectileParameters.speed, self.projectileGravityMultiplier-0.4, true)
	else
	  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
	  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	  self.aimTypeSwitchTimer = 0.1 --Hold the last aiming type for a brief moment to smooth transitions
	  return aimVector
	end
  end
end

function NebArrowRain:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function NebArrowRain:splitAngle(up, low, n)
    assert(up >= low)
    assert(n > 0)
    local angles = {}
    local mid = low + (up - low) / 2.0
    print(string.format("n == %s mid=%s", n, mid))

    if n == 1 then
        return {mid}
    else
        table.insert(angles, self:splitAngle(up, mid, math.floor(n / 2)))
        if n % 2 == 1 then
            table.insert(angles, mid)
        end
        table.insert(angles, self:splitAngle(mid, low, math.floor(n / 2)))

        return angles
    end
end

function NebArrowRain:unpack(tab)
    local unpacked = {}
    for _, v in ipairs(tab) do
        if type(v) == "table" then
            local t = self:unpack(v)
            for _, vv in ipairs(t) do
                table.insert(unpacked, vv)
            end
        else
            table.insert(unpacked, v)
        end
    end
    return unpacked
end
