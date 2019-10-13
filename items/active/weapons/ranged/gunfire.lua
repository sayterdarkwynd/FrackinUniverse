require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/crits.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
-- FU additions
  self.isReloader = config.getParameter("isReloader",0)  -- is this a shotgun style reload?
  self.isCrossbow = config.getParameter("isCrossbow",0)  -- is this a crossbow?
  self.isSniper = config.getParameter("isSniper",0)  -- is this a sniper rifle?
  self.countdownDelay = 0 --how long till crossbow regains damage bonus?
  self.timeBeforeCritBoost = 2
  
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
-- *** FU Weapon Additions
  if self.timeBeforeCritBoost <= 0 then
  	  self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
	  if self.isCrossbow >= 1 then
		self.countdownDelay = (self.countdownDelay or 0) + 1
		self.weaponBonus = (self.weaponBonus or 0)
		self.firedWeapon = (self.firedWeapon or 0)
		if self.firedWeapon > 0 then
			if self.countdownDelay > 20 then
				self.weaponBonus = 0
				self.countdownDelay = 0
				self.firedWeapon = 0
			end 	
		else
			if self.countdownDelay > 20 then
				self.weaponBonus = (self.weaponBonus or 0) + (config.getParameter("critBonus") or 1)
				self.countdownDelay = 0
			end 	
		end

		if self.weaponBonus >= 50 then --limit max value for crits and let player know they maxed
			self.weaponBonus = 50
			status.addEphemeralEffect("critReady", 0.25)
		end
		status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus}})
	  end
	  self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
	  if self.isSniper >= 1 then
		self.countdownDelay = (self.countdownDelay or 0) + 1
		self.weaponBonus = (self.weaponBonus or 0)
		self.firedWeapon = (self.firedWeapon or 0)
		if self.firedWeapon > 0 then
			if self.countdownDelay > 10 then
				self.weaponBonus = 0
				self.countdownDelay = 0
				self.firedWeapon = 0
			end 	
		else
			if self.countdownDelay > 10 then
				self.weaponBonus = (self.weaponBonus or 0) + (config.getParameter("critBonus") or 1)
				self.countdownDelay = 0
			end 	
		end

		if self.weaponBonus >= 80 then --limit max value for crits and let player know they maxed
			self.weaponBonus = 80
			status.addEphemeralEffect("critReady", 0.25)
		end
		status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus}})

	  end   
  else
    self.timeBeforeCritBoost = self.timeBeforeCritBoost -dt
  end
  
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
  end
end

function GunFire:auto()
    --Crossbows
  	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
  	  if (self.isCrossbow) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 1
	  end 
    --Snipers	  
  	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
  	  if (self.isSniper) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 2
	  end 	
	
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

function GunFire:burst()
    --Crossbows
  	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
  	  if (self.isCrossbow) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 1
	  end 
    --Snipers	  
  	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
  	  if (self.isSniper) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 2
	  end 
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

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:cooldown()

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

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
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

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()      --return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
    return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end

function GunFire:uninit()
  status.clearPersistentEffects("weaponBonus")
end
