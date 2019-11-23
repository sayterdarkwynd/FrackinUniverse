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
  self.isReloader = config.getParameter("isReloader",0)  					-- is this a shotgun style reload?
  self.isCrossbow = config.getParameter("isCrossbow",0)  					-- is this a crossbow?
  self.isSniper = config.getParameter("isSniper",0)  						-- is this a sniper rifle?
  self.isAmmoBased = config.getParameter("isAmmoBased",0)  					-- is this a ammo based gun?
  self.isMachinePistol = config.getParameter("isMachinePistol",0)  				-- is this a machine pistol?
  self.isShotgun = config.getParameter("isShotgun",0)  						-- is this a shotgun?
  -- params
  self.countdownDelay = 0 									-- how long till it regains damage bonus?
  self.timeBeforeCritBoost = 2 									-- how long before it starts accruing bonus again?
  self.playerMagBonus = status.stat("magazineSize",0)						-- player  ammo bonuses
  self.playerReloadBonus = status.stat("reloadTime",0)						-- player reload bonuses
  self.magazineSize = config.getParameter("magazineSize",1) + (self.playerMagBonus or 0) 	-- total count of the magazine
  self.magazineAmount = (self.magazineSize or 0) 						-- current number of bullets in the magazine
  self.reloadTime = config.getParameter("reloadTime",1)	+ (self.playerReloadBonus or 0) 	-- how long does reloading mag take?
  
  
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
-- *** FU Weapon Additions

  if self.magazineAmount < 0 or not self.magazineAmount then --make certain that ammo never ends up in negative numbers
    self.magazineAmount = 0 
  end
  
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
			status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
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
			status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
			status.addEphemeralEffect("critReady", 0.25)
		end
		status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus}})

	  end   
  else
    self.timeBeforeCritBoost = self.timeBeforeCritBoost -dt
  end
  
  
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
	self.reloadTime = config.getParameter("reloadTime") or 1		-- how long does reloading mag take?
  self.weapon:setStance(self.stances.fire)

    --Crossbows
  	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
  	  if (self.isCrossbow) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 1
	    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
	  end 
    --Snipers	  
  	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
  	  if (self.isSniper) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 2
	    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
	  end 	  
    --ammo		
    	  self.magazineSize = config.getParameter("magazineSize",1) + (self.playerMagBonus or 0)		-- total count of the magazine  
          self.magazineAmount = (self.magazineAmount or 0)-- current number of bullets in the magazine
	  self.isAmmoBased = config.getParameter("isAmmoBased",0) -- is this a pistol?	   
	  if (self.isAmmoBased == 1) then 
	    if self.magazineAmount <= 0 then
	        self.weapon:setStance(self.stances.cooldown)
		self:setState(self.cooldown)
	    else
	      self.magazineAmount = self.magazineAmount - 1
	    end
	  end	
	  
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
	self.isReloader = config.getParameter("isReloader",0)  		-- is this a shotgun style reload?
   	if self.isReloader >= 1 then
   	  animator.playSound("cooldown") -- adds sound to shotgun reload
 		if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
 		    animator.playSound("fuReload") -- adds new sound to reload 
 		end  	  
 	end	
 	if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
 	    self.cooldownTimer = self.fireTime + self.reloadTime
 	    status.addEphemeralEffect("reloadReady", 0.5)
 	    self.magazineAmount = self.magazineSize
	    self.reloadTime = config.getParameter("reloadTime",0)
	    if (self.reloadTime < 1) then
	       animator.playSound("fuReload") -- adds new sound to reload 
	    elseif (self.reloadTime >= 2.5) then
	       animator.playSound("fuReload5") -- adds new sound to reload 
	    elseif (self.reloadTime >= 2) then
	       animator.playSound("fuReload4") -- adds new sound to reload 
	    elseif (self.reloadTime >= 1.5) then
	       animator.playSound("fuReload3") -- adds new sound to reload 	       
	    elseif (self.reloadTime >= 1) then
	       animator.playSound("fuReload2") -- adds new sound to reload 
	    end
	    self.weapon:setStance(self.stances.cooldown)
	    self:setState(self.cooldown) 	    
	end
	  
  self:setState(self.cooldown)
end

function GunFireFixed:burst() -- burst auto should be a thing here

  self.weapon:setStance(self.stances.fire)
    --Crossbows
  	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
  	  if (self.isCrossbow) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 2
	    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
	  end 
    --Snipers	  
  	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
  	  if (self.isSniper) >= 1 then 
	    self.firedWeapon = 1
	    self.timeBeforeCritBoost = 2
	    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
	  end 	
    --ammo		
    	  self.magazineSize = config.getParameter("magazineSize",1) + (self.playerMagBonus or 0)		-- total count of the magazine  
          self.magazineAmount = (self.magazineAmount or 0)-- current number of bullets in the magazine
	  self.isAmmoBased = config.getParameter("isAmmoBased",0) -- is this a pistol?	   
	  if (self.isAmmoBased == 1) then 
	    if self.magazineAmount <= 0 then
	        self.weapon:setStance(self.stances.cooldown)
		self:setState(self.cooldown)
	    else
	      self.magazineAmount = self.magazineAmount - 1
	    end
	  end	
	  
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
        self.isReloader = config.getParameter("isReloader",0)  		-- is this a shotgun style reload?
  	if self.isReloader >= 1 then
  	  animator.playSound("cooldown") -- adds sound to shotgun reload
		if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
		    animator.playSound("fuReload") -- adds new sound to reload 
		end  	  
	end	
	if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
	    self.cooldownTimer = self.burstCooldown + self.reloadTime
	    status.addEphemeralEffect("reloadReady", 0.5)
	    self.magazineAmount = self.magazineSize
	    self.reloadTime = config.getParameter("reloadTime",0)
	    if (self.reloadTime < 0.08) then
	       animator.playSound("fuReload") -- adds new sound to reload 
	    elseif (self.reloadTime >= 1) then
	       animator.playSound("fuReload2") -- adds new sound to reload 
	    elseif (self.reloadTime >= 1.5) then
	       animator.playSound("fuReload3") -- adds new sound to reload 
	    elseif (self.reloadTime >= 2) then
	       animator.playSound("fuReload4") -- adds new sound to reload 
	    elseif (self.reloadTime >= 2.5) then
	       animator.playSound("fuReload5") -- adds new sound to reload 
	    end
	    self.weapon:setStance(self.stances.cooldown)
	    self:setState(self.cooldown)	    
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
  --elseif self.isAmmoBased then  --ammo based guns use 1/2 as much energy
  --  return (self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0))/2
  else
    return 0
  end
end

function GunFireFixed:damagePerShot()
  return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end

function GunFireFixed:uninit()
  status.clearPersistentEffects("weaponBonus")
end
