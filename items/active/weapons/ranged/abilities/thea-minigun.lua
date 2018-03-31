require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Bow primary ability
TheaMinigun = WeaponAbility:new()

function TheaMinigun:init()

  self.chargeTimer = self.chargeTime
  self.cooldownTimer = self.fireTime
  
  animator.setAnimationState("charge", "off")
  animator.setAnimationState("chargehold", "off")
  
  self.chargeHasStarted = false
  self.shouldDischarge = false
  self.windupReady = false
  
  self.chargeSoundIsPlaying = false
  self.holdSoundIsPlaying = false
  
  self.resetTimer = self.resetTime

  self:reset()

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function TheaMinigun:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  --If holding fire, and nothing is holding back the charging process
  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
	and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
	and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    self:setState(self.charge)
	
  --Count down the reset timer (how long the charge remains after the player stops firing)
  elseif self.windupReady == true and (self.fireMode ~= (self.activatingFireMode or self.abilitySlot) or world.lineTileCollision(mcontroller.position(), self:firePosition())) then
    self.resetTimer = math.max(0, self.resetTimer - self.dt)
	--If the reset timer hits zero
	if self.resetTimer == 0 then
	  animator.stopAllSounds("holdLoop")
	  self.holdSoundIsPlaying = false
	  self.chargeSoundIsPlaying = false
	  self.chargeHasStarted = false
	  self.windupReady = false
	  animator.setAnimationState("charge", "off")
	  animator.setAnimationState("chargehold", "off")
	  self.chargeTimer = self.chargeTime
	  self.resetTimer = self.resetTime
	end
	
  --If we run out of energy while firing
  elseif self.windupReady == true and status.resourceLocked("energy") then
    animator.stopAllSounds("holdLoop")
	self.holdSoundIsPlaying = false
	self.chargeSoundIsPlaying = false
	self.chargeHasStarted = false
	self.windupReady = false
	animator.setAnimationState("charge", "off")
	animator.setAnimationState("chargehold", "off")
	self.chargeTimer = self.chargeTime
	self.resetTimer = self.resetTime
  
  --If the charge was prematurily stopped or somehow interrupted
  elseif self.chargeHasStarted == true and (self.fireMode ~= (self.activatingFireMode or self.abilitySlot) or world.lineTileCollision(mcontroller.position(), self:firePosition())) then
    animator.stopAllSounds("chargeLoop")
	self.chargeSoundIsPlaying = false
	animator.setAnimationState("charge", "off")
	self.chargeTimer = self.chargeTime
  end
  
  --Movement suppressor
  if self.walkWhileFiring == true and (self.chargeHasStarted == true or self.windupReady == true) then
    mcontroller.controlModifiers({runningSuppressed=true})
  end
  
  --Charge/hold animation manager
  if self.chargeHasStarted == true then
    animator.setAnimationState("charge", "charging")
  elseif self.windupReady == true then
    animator.setAnimationState("chargehold", "on")
  end
end

function TheaMinigun:charge()
  self.weapon:setStance(self.stances.charge)
  
  --While charging, but not yet ready, count down the charge timer
  while self.chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) do
    self.chargeTimer = math.max(0, self.chargeTimer - self.dt)
	
	self.chargeHasStarted = true
	
	--Prevent energy regen while charging
	status.setResourcePercentage("energyRegenBlock", 0.6)
	
	if self.chargeSoundIsPlaying == false then
	  animator.playSound("chargeLoop", -1)
	  self.chargeSoundIsPlaying = true
	end

    coroutine.yield()
  end
  
  --If the charge is ready, keep on firing so long as we have energy left
  if self.chargeTimer == 0 and status.overConsumeResource("energy", self:energyPerShot()) then    
	self.resetTimer = self.resetTime
	self.chargeHasStarted = false
	self.windupReady = true
	
	if self.holdSoundIsPlaying == false then
	  animator.playSound("holdLoop", -1)
	  animator.stopAllSounds("chargeLoop")
	  self.chargeSoundIsPlaying = false
	  self.holdSoundIsPlaying = true
	end
	
    self:setState(self.fire)
  --If not charging and charge isn't ready, go to cooldown
  else
	animator.playSound("discharge")
	self.shouldDischarge = true
    self:setState(self.cooldown)
  end
end

function TheaMinigun:fire()
  self.weapon:setStance(self.stances.fire)
  
  --Fire a projectile and show a muzzleflash, then continue on with this state
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end
  
  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function TheaMinigun:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
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
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function TheaMinigun:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function TheaMinigun:cooldown()
  
  if self.shouldDischarge == true then
    self.weapon:updateAim()
	self.weapon:setStance(self.stances.discharge)
	self.shouldDischarge = false
	
	local progress = 0
    util.wait(self.stances.discharge.duration, function()
      local from = self.stances.discharge.weaponOffset or {0,0}
      local to = self.stances.idle.weaponOffset or {0,0}
      self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

      self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.discharge.weaponRotation, self.stances.idle.weaponRotation))
      self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.discharge.armRotation, self.stances.idle.armRotation))

      progress = math.min(1.0, progress + (self.dt / self.stances.discharge.duration))
    end)
  else
    self.weapon:updateAim()
	self.weapon:setStance(self.stances.cooldown)
	
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
end

function TheaMinigun:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function TheaMinigun:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function TheaMinigun:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function TheaMinigun:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function TheaMinigun:uninit()
  self:reset()
end

function TheaMinigun:reset()
  animator.setAnimationState("charge", "off")
  --animator.setAnimationState("chargehold", "off")
  self.chargeHasStarted = false
  self.weapon:setStance(self.stances.idle)
end