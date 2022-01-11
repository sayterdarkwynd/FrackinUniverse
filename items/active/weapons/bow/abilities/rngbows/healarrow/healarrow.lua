--Modified bow shot ability that drains energy while drawing and holding, with configurable drain rates. Has an animation state for when arrows have been loosed
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

-- Bow primary ability
NebRNGHealPoint = WeaponAbility:new()

function NebRNGHealPoint:init()
  self.energyPerShot = self.energyPerShot or 0
  animator.setGlobalTag("directives", config.getParameter("directives", ""))
  self.paletteSwaps = config.getParameter("paletteSwaps")
  self.elementalType = config.getParameter("elementalType")
  self.cannotUseAlt = false

  self.drawTimer = 0
  animator.setAnimationState("bow", "idle")
  self.cooldownTimer = 0

  self:reset()

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function NebRNGHealPoint:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  world.debugText(self.fireMode, mcontroller.position(), "yellow")

  world.debugPoint(self:firePosition(), "red")

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and self.cannotUseAlt == false and (self.drawTimer > 0 or not status.resourceLocked("energy")) then
	animator.stopAllSounds("chargeLoopAlt")
	animator.setAnimationState("chargeAlt", "off")
	animator.setParticleEmitterActive("chargeparticlesAlt", false)
	self:setState(self.draw)
  end
end

function NebRNGHealPoint:uninit()
  self:reset()
end

function NebRNGHealPoint:reset()
  self.waitTimer = self.maxWaitTime
  self.targetPosition = nil
  self.cannotUseAlt = false
  animator.stopAllSounds("chargeLoopAlt")
  animator.setAnimationState("chargeAlt", "off")
  animator.setParticleEmitterActive("chargeparticlesAlt", false)
end

function NebRNGHealPoint:draw()
  self.weapon:setStance(self.stances.draw)

  animator.playSound("draw", -1)
  animator.playSound("chargeLoopAlt")
  animator.setAnimationState("chargeAlt", "charging")
  animator.setParticleEmitterActive("chargeparticlesAlt", true)
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
	elseif self.drawTimer > self.drawTime and self.drawTimer <= (self.drawTime) then
	  status.setResourcePercentage("energyRegenBlock", 0.6)
	  drawFrame = #self.drawArmFrames - 1
	  if self.drainEnergyWhilePowerful then
		status.overConsumeResource("energy", self.holdEnergyUsage * self.dt) --Optionally drain energy while at max power level
	  end

	--If drawn beyond power peak levels, drain energy slowly
	elseif self.drawTimer > (self.drawTime) then
	  status.overConsumeResource("energy", self.holdEnergyUsage * self.dt)
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

    animator.setGlobalTag("drawFrame", drawFrame)

    self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

	--world.debugText(sb.printJson(self:currentProjectileParameters(), 1), mcontroller.position(), "yellow")

    coroutine.yield()
  end

  animator.stopAllSounds("draw")
  self:setState(self.fire)
end

function NebRNGHealPoint:fire()
  self.hasChargedCursor = false
  activeItem.setCursor(self.cursorFrames[1])
  self.weapon:setStance(self.stances.fire)

  animator.stopAllSounds("chargeLoopAlt")
  animator.setAnimationState("chargeAlt", "off")
  animator.setParticleEmitterActive("chargeparticlesAlt", false)

  animator.setGlobalTag("drawFrame", "0")
  animator.setGlobalTag("directives", "")
  animator.stopAllSounds("ready")

  if not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    if self.elementalType ~= "physical" then
        self.projectileParameters.damageKind = self.elementalType .. "bow"
    end
    for _ = 1, (self.projectileCount or 1) do
	  self.teleportProjectile = world.spawnProjectile(
        self.projectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(),
        false,
        self:currentProjectileParameters()
      )
	end

	animator.setAnimationState("bow", "loosed")

    self.drawTimer = 0

    util.wait(self.stances.fire.duration)
  else
	animator.playSound("dischargeAlt")
  end

  self.projectileParameters.periodicActions = nil
  self.cooldownTimer = self.cooldownTime
  animator.setGlobalTag("directives", "")
  self.waitTimer = self.waitTime

  self.weapon:setStance(self.stances.idle)
  animator.setGlobalTag("drawFrame", "0")
  animator.setAnimationState("bow", "idle")
  animator.stopAllSounds("draw")
  animator.stopAllSounds("ready")

  self.cannotUseAlt = true

  while world.entityExists(self.teleportProjectile) do
	world.debugText("Active projectiles detected!", mcontroller.position(), "green")

	self.targetPosition = world.entityPosition(self.teleportProjectile)

	--Make sure we don't wait don't wait too long, and kill the projectile otherwise
	self.waitTimer = math.max(0, self.waitTimer - self.dt)
	if self.waitTimer == 0 then
	  if self.teleportProjectile then
		world.sendEntityMessage(self.teleportProjectile, "kill")
		--self.targetPosition = nil
	  end
	end
    coroutine.yield()
  end

  --Attempt to teleport the player
  self:setState(self.attemptTeleport)
end


function NebRNGHealPoint:currentProjectileParameters()
  --Set projectile parameters based on draw power level
  local projectileParameters = copy(self.projectileParameters or {})
  --Load the root projectile config based on draw power level
  local projectileConfig = root.projectileConfig(self.projectileType)

  --Calculate projectile speed based on draw time and projectile parameters
  projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
  projectileParameters.speed = projectileParameters.speed * math.min(1, (self.drawTimer / self.drawTime))

  projectileParameters.processing = self.paletteSwaps

  --Bonus damage calculation for quiver users
  local damageBonus = 1.0
  if self.useQuiverDamageBonus == true and status.statPositive("avikanQuiver") then
	damageBonus = status.stat("avikanQuiver")
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

function NebRNGHealPoint:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

function NebRNGHealPoint:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end
