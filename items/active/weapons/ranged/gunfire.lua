require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/crits.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
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
  self.magazineSize = (config.getParameter("magazineSize",1) + (self.playerMagBonus or 0) or 6) -- total count of the magazine
  self.magazineAmount = (self.magazineSize or 0) 						-- current number of bullets in the magazine
  self.reloadTime = config.getParameter("reloadTime",1)	+ (self.playerReloadBonus or 0) 	-- how long does reloading mag take?
  
  self.isRecoil = 0--when fired, has recoil
  self.recoilSpeed = 0-- speed of recoil
  self.recoildForce = 0--force of recoil
  
  self.weapon:setStance(self.stances.idle)
  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  
  self.playerId = entity.id()
  self.currentAmmoPercent = self.magazineAmount / self.magazineSize
  if self.currentAmmoPercent > 1.0 then
    self.currentAmmoPercent = 1
  end  
  if (self.isAmmoBased == 1) then
    self.timerRemoveAmmoBar = 0 
  end  
  self.barName = "ammoBar"
  self.barColor = {0,250,112,125}
  

  self.hasRecoil = (config.getParameter("hasRecoil",0))--when fired, does the weapon have recoil?
  self.recoilSpeed = (config.getParameter("recoilSpeed",0))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
  self.recoilForce = (config.getParameter("recoilForce",0)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire
  
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  -- *** FU Weapon Additions
  if self.timeBeforeCritBoost <= 0 then  --check sniper crit bonus
      self:isChargeUp()
  else
      self.timeBeforeCritBoost = self.timeBeforeCritBoost -dt
  end
  
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  if self.loadingUp then
    self.loadupTimer = math.max(0, self.loadupTimer - self.dt)
  end
  if self.cooldownTimer == 0 then 
    -- set the cursor to the FU White cursor
    if (self.isAmmoBased == 1) then
      activeItem.setCursor("/cursors/fureticle0.cursor")
    else
      activeItem.setCursor("/cursors/reticle0.cursor")
    end
  end
  
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
  
  --Recoil here
  if (self.hasRecoil == 1) then
    if self.fireMode ~= "alt" then
      self.recoilForce = self.recoilForce * self.fireTime
    else
      self.recoilForce * 0.15
    end
    local recoilDirection = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
    mcontroller.controlApproachVelocityAlongAngle(recoilDirection, self.recoilSpeed, self.recoilForce, true)    
  end
end

function GunFire:auto()
    --ammo
    self.reloadTime = config.getParameter("reloadTime") or 1		-- how long does reloading mag take?	
    self:checkMagazine()--ammo system magazine check
    -- recoil
    self.recoilSpeed = (config.getParameter("recoilSpeed",0))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
    self.recoilForce = (config.getParameter("recoilForce",0)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire    
	  
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime

 	--FU/FR special checks
        self.isReloader = config.getParameter("isReloader",0)  		-- is this a shotgun style reload?
  	if self.isReloader >= 1 then
  	  animator.playSound("cooldown") -- adds sound to shotgun reload
		if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
		    animator.playSound("fuReload") -- adds new sound to reload 
		end  	  
	end
        self:checkAmmo() --is it an ammo user?
	
	self.weapon:setStance(self.stances.cooldown)
	self:setState(self.cooldown)
end

function GunFire:burst()
    --ammo	
    self.reloadTime = config.getParameter("reloadTime") or 1		-- how long does reloading mag take?	
    self:checkMagazine()--ammo system magazine check	
    -- recoil stats reset every time we shoot so that it is consistent
    self.recoilSpeed = (config.getParameter("recoilSpeed",0))
    self.recoilForce = (config.getParameter("recoilForce",0)) 
    
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
 	--FU/FR special checks
        self:hasShotgunReload()--reloads as a shotgun?
        self:checkAmmo() --is it an ammo user?
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
  self.timerReloadBar = 0 -- reset reload timer
  self:isResetting() --check if we reset the FU/FR crit bonus for crossbow and sniper
  
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
  --Recoil here
  self:applyRecoil()  
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
  if (self.isAmmoBased == 1) and not (self.fireMode == "alt") then
    return (self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0))/2
  else
    return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
  end
end

function GunFire:damagePerShot()      --return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
    return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end

function GunFire:uninit()
  status.clearPersistentEffects("weaponBonus") 
end


function GunFire:isResetting()
  -- FR/FU crossbow/sniper specials get reset here
  if (self.isSniper == 1) or (self.isCrossbow == 1) then
    self.firedWeapon = 1
    self.timeBeforeCritBoost = 2   
    status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
  end
end

function GunFire:isChargeUp()
  self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
  self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
  if (self.isCrossbow >= 1) or (self.isSniper >= 1) then
	  self.countdownDelay = (self.countdownDelay or 0) + 1
	  self.weaponBonus = (self.weaponBonus or 0)
	  self.firedWeapon = (self.firedWeapon or 0)  
	if (self.firedWeapon >= 1) then
		if (self.isCrossbow == 1) then
			if self.countdownDelay > 20 then
				self.weaponBonus = 0
				self.countdownDelay = 0
				self.firedWeapon = 0
			end 		
		end
		
		if (self.isSniper == 1) then
			if self.countdownDelay > 10 then
				self.weaponBonus = 0
				self.countdownDelay = 0
				self.firedWeapon = 0
			end 			
		end
	else
		if self.countdownDelay > 20 then
			self.weaponBonus = (self.weaponBonus or 0) + (config.getParameter("critBonus") or 1)
			self.countdownDelay = 0
		end 	
	end
	
	if (self.isSniper == 1) and (self.weaponBonus >= 80) then --limit max value for crits and let player know they maxed
		self.weaponBonus = 80
		status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
		status.addEphemeralEffect("critReady")
	end
	
	if (self.isCrossbow == 1) and (self.weaponBonus >= 50) then --limit max value for crits and let player know they maxed
		self.weaponBonus = 50
		status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
		status.addEphemeralEffect("critReady")
	end
	status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus}}) -- set final bonus value
  end  
end

function GunFire:hasShotgunReload()
        self.isReloader = config.getParameter("isReloader",0)  		-- is this a shotgun style reload?
  	if self.isReloader >= 1 then
  	  animator.playSound("cooldown") -- adds sound to shotgun reload
		if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
		    animator.playSound("fuReload") -- adds new sound to reload 
		end  	  
	end
end

function GunFire:checkAmmo()	
             -- set the cursor to the Reload cursor
	if (self.isAmmoBased==1) then  -- ammo bar color check
		if self.currentAmmoPercent <= 0 then
			self.barColor = {0,0,0,255}
		end	
		if self.currentAmmoPercent > 0.75 then
			self.barColor = {0,250,112,125}
			activeItem.setCursor("/cursors/fureticle1.cursor")
		end	
		if self.currentAmmoPercent <= 0.75 then
			self.barColor = {130,201,49,125}
			activeItem.setCursor("/cursors/fureticle1.cursor")
		end	
		if self.currentAmmoPercent <= 0.65 then
			self.barColor = {167,201,49,125}
			activeItem.setCursor("/cursors/fureticle2.cursor")
		end		
		if self.currentAmmoPercent <= 0.55 then
			self.barColor = {201,179,49,125}
			activeItem.setCursor("/cursors/fureticle3.cursor")
		end		
		if self.currentAmmoPercent <= 0.45 then
			self.barColor = {201,133,49,125}
			activeItem.setCursor("/cursors/fureticle4.cursor")
		end	
		if self.currentAmmoPercent <= 0.25 then
			self.barColor = {201,49,49,125}	
			activeItem.setCursor("/cursors/fureticle5.cursor")
		end 	
        end	
	if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then 
	    if self.burstCooldown then
	      self.cooldownTimer = self.burstCooldown + self.reloadTime
	    else
	      self.cooldownTimer = self.fireTime + self.reloadTime
	    end  
	    status.addEphemeralEffect("reloadReady", 0.5)
	    self.magazineAmount = self.magazineSize
	    self.reloadTime = config.getParameter("reloadTime",0)
            -- set the cursor to the Reload cursor
            activeItem.setCursor("/cursors/cursor_reload.cursor")	    
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
	    
  	--check current ammo and create an ammo bar to inform the user
  	self.currentAmmoPercent = 1.0
  	self.barColor = {0,250,112,125}
	
	if (self.fireMode == "primary") then
  	world.sendEntityMessage(
  	  self.playerId,
  	  "setBar",
  	  "ammoBar",
  	  self.currentAmmoPercent,
  	  self.barColor
	)
	end
	    self.weapon:setStance(self.stances.cooldown)
	    self:setState(self.cooldown)
	end
end

function GunFire:checkMagazine()
  self.magazineSize = config.getParameter("magazineSize",1) + (self.playerMagBonus or 0)		-- total count of the magazine    
  self.magazineAmount = (self.magazineAmount or 0)-- current number of bullets in the magazine
  self.isAmmoBased = config.getParameter("isAmmoBased",0)   
  if (self.isAmmoBased == 1) then 
  	--check current ammo and create an ammo bar to inform the user
  	self.currentAmmoPercent = self.magazineAmount / self.magazineSize
	if self.currentAmmoPercent <= 0 then
		self.barColor = {0,0,0,125}
  	elseif self.currentAmmoPercent > 0.75 then
  		self.barColor = {0,255,0,125}
  	elseif self.currentAmmoPercent <= 0.75 then
		self.barColor = {125,255,0,125}  
	elseif self.currentAmmoPercent <= 0.50 then
		self.barColor = {255,255,0,125}	
	elseif self.currentAmmoPercent <= 0.25 then
		self.barColor = {255,0,0,125}		
	end           
        if (self.fireMode == "primary") then
  	world.sendEntityMessage(
  	  self.playerId,
  	  "setBar",
  	  "ammoBar",
  	  self.currentAmmoPercent,
  	  self.barColor
	)  
	end
    if self.magazineAmount <= 0 then
	self.weapon:setStance(self.stances.cooldown)
	self:setState(self.cooldown)
	self.magazineAmount = 0 
    else
      self.magazineAmount = self.magazineAmount - 1
    end
  end
end

function GunFire:applyRecoil()
  --Recoil here
  if (self.hasRecoil == 1) then  						--does the weapon have recoil?
    if (self.fireMode == "primary") then					--is it primary fire?
      self.recoilForce = self.recoilForce * self.fireTime
      self:adjustRecoil()
    else
      self.recoilForce = self.recoilForce * 0.15
      self:adjustRecoil()
    end
    local recoilDirection = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
    mcontroller.controlApproachVelocityAlongAngle(recoilDirection, self.recoilSpeed, self.recoilForce, true)    
  end
end

function GunFire:adjustRecoil()		-- if we are not grounded, we halve the force of the recoil				
    if not mcontroller.onGround() then						
     self.recoilForce = self.recoilForce * 0.5
    end
    if mcontroller.crouching() then
     self.recoilForce = self.recoilForce * 0.25
    end      
end