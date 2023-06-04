--activeItem.setInstanceValue() can be used to set a property on the active item (ammo reload pause if discarding)
--and the property should be accessible via config.getParameter()
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/FRHelper.lua"
require "/items/active/weapons/crits.lua"
require "/stats/effects/fu_statusUtil.lua"

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
	self.ownerId = activeItem.ownerEntityId()
	self.ownerType=world.entityType(self.ownerId)
	-- FU additions
	self.isReloader = config.getParameter("isReloader",0) -- is this a shotgun style reload?
	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
	--self.isAmmoBased = config.getParameter("isAmmoBased",0) -- is this a ammo based gun?

	-- is this a ammo based gun? if so, the primary gets the parameters off the weapon
	-- adding support, of course, for alts that are explicitly ammo based.
	self.isAmmoBased = self.isAmmoBased or ((self.abilitySlot=="primary") and config.getParameter("isAmmoBased",0))
	self.isMachinePistol = config.getParameter("isMachinePistol",0) -- is this a machine pistol?
	self.isShotgun = config.getParameter("isShotgun",0) -- is this a shotgun?
	-- params
	self.countdownDelay = 0 -- how long till it regains damage bonus?
	self.timeBeforeCritBoost = 2 -- how long before it starts accruing bonus again?

	self:calcAmmo()
	local defaultMag=((self.ownerType=="player") and -1) or self.magazineSize
	--self.magazineAmount = math.min(config.getParameter("magazineAmount",defaultMag),self.magazineSize) -- current number of bullets in the magazine
	--self.magazineAmount=config.getParameter("magazineAmount",defaultMag)
	self.magazineAmount=config.getParameter("magazineAmount"..self.abilitySlot,defaultMag)
	self.reloadTime = math.max(0,config.getParameter("reloadTime",1) + status.stat("reloadTime")) -- how long does reloading mag take?

	if (self.isAmmoBased==1) then
		self.timerRemoveAmmoBar = 0
		self.currentAmmoPercent = util.clamp(self.magazineAmount / self.magazineSize,0.0,1.0)
		self.isReloading=((self.ownerType=="player") and config.getParameter("isReloading"..self.abilitySlot,true)) or (self.magazineAmount <= 0)
	end
	self.barName = "ammoBar"
	self.barColor = {0,250,112,125}

	-- **** FR ADDITIONS
	daytime = daytimeCheck()
	underground = undergroundCheck()
	lightLevel = 1

	-- bonus add for novakids with pistols when sped up, specifically to energy and damage equations at end of file so that they still damage and consume energy at high speed
	self.energyMax = 1
	-- ** END FR ADDITIONS

	self.weapon:setStance(self.stances.idle)

	if (self.isAmmoBased==1) then
		if (not self.isReloading) and (self.magazineAmount >= 0) then
			self.cooldownTimer=self.fireTime/10.0
		else
			self:checkAmmo(true)
			self:checkMagazine(true)
			--activeItem.setInstanceValue("isReloading",self.isReloading)
			--self.cooldownTimer=self.fireTime+self.reloadTime
		end
	else
		self.cooldownTimer = self.fireTime
	end
	--self.cooldownTimer = self.cooldownTimer * self.playerSpeedBonus--removed
	if self.loadupTime then
		self.loadupTimer = self.loadupTime
	else
		self.loadupTimer = 0
	end
	self.loadingUp = false

	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end

	self.hasRecoil = (config.getParameter("hasRecoil",0))--when fired, does the weapon have recoil?
	self.recoilSpeed = (config.getParameter("recoilSpeed",0))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
	self.recoilForce = (config.getParameter("recoilForce",0)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire
end

function GunFireFixed:calcAmmo()
	local oldSize=self.magazineSize
	local magazineTemp=(self.ammoInheritanceMult or 1.0)*config.getParameter("magazineSize",1)
	self.magazineSize = magazineTemp*(1+status.stat("magazineMultiplier")) + math.max(0,status.stat("magazineSize")) -- total count of the magazine
	if (oldSize and oldSize~= self.magazineSize) then return true,oldSize end
end

-- ***********************************************************************************************************
-- ***********************************************************************************************************

function GunFireFixed:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	-- *** FU Weapon Additions
	if self.timeBeforeCritBoost <= 0 then	--check sniper/crossbow crit bonus
		self:isChargeUp()
	else
		self.timeBeforeCritBoost = self.timeBeforeCritBoost -dt
	end

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.loadingUp then
		self.loadupTimer = math.max(0, self.loadupTimer - self.dt)
	end
	if self.cooldownTimer==0 then
		local changed,from=self:calcAmmo()
		if changed then
			if self.magazineSize>from then
				self.magazineAmount=math.min(self.magazineSize,self.magazineAmount+(self.magazineSize-from))
			elseif self.magazineSize < from then
				self.magazineAmount=math.min(self.magazineSize,self.magazineAmount)
			end
		end
		self.isReloading = false
		-- set the cursor to the FU White cursor
		if (self.isAmmoBased==1) then
			activeItem.setCursor("/cursors/fureticle0.cursor")
		else
			activeItem.setCursor("/cursors/reticle0.cursor")
		end
	end

	setupHelper(self, {"gunfire-update", "gunfire-auto", "gunfire-postauto", "gunfire-burst", "gunfire-postburst"})
	if self.helper then
		self.helper:runScripts("gunfire-update", self, dt, fireMode, shiftHeld)
	end

	if self.loadingUp then
		self.loadupTimer = math.max(0, self.loadupTimer - self.dt)
	end

	if animator.animationState("firing") ~= "fire" then
		animator.setLightActive("muzzleFlash", false)
	end

	if self.fireMode==(self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if self.runSlowWhileShooting then
			mcontroller.controlModifiers({groundMovementModifier = 0.5,
			speedModifier = 0.65,
			airJumpModifier = 0.80})
		end
	elseif (not self.fireMode) and self.runSlowWhileShooting then
		mcontroller.clearControls()
	end

	if (self.isAmmoBased==1) and shiftHeld and (fireMode==self.abilitySlot) and self.currentAmmoPercent and (self.currentAmmoPercent < 1.0) then
		self:checkAmmo(true)
	elseif not (self.fireMode==(self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") and not world.lineTileCollision(mcontroller.position(), self:firePosition())) then
		if self.loadupTime then
			self.loadupTimer = self.loadupTime
		else
			self.loadupTimer = 0
		end
		self.loadingUp = false
	end

	if self.fireMode==(self.activatingFireMode or self.abilitySlot) and not self.weapon.currentAbility and self.cooldownTimer==0 and not status.resourceLocked("energy") and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if self.loadupTimer==0 then
			if self.weaponBonus and fireMode=="primary" then
				status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus},{stat="fu_firedWeapon",amount=1}})
			end
			if self.fireType=="auto" and status.overConsumeResource("energy", self:energyPerShot()) then
				self:setState(self.auto)
				self:checkMagazine(true)
			elseif self.fireType=="burst" then
				self:setState(self.burst)
				self:checkMagazine(true)
			end
			if status.statPositive("fu_firedWeapon") then
				status.setPersistentEffects("weaponBonus", {{stat="fu_cleanupWeaponBonus",amount=1}})
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
	-- ***********************************************************************************************************
	-- FR SPECIALS	(Weapon speed and other such things)
	-- ***********************************************************************************************************
	--ammo
	self.reloadTime = config.getParameter("reloadTime") or 1		-- how long does reloading mag take?
	self:checkMagazine()--ammo system magazine check
	-- recoil stats reset every time we shoot so that it is consistent
	self.recoilSpeed = (config.getParameter("recoilSpeed",200))
	self.recoilForce = (config.getParameter("recoilForce",100))

	if self.helper then
		self.helper:runScripts("gunfire-auto", self)
	end

	self.weapon:setStance(self.stances.fire)

	self:fireProjectile()
	self:muzzleFlash()

	if self.stances.fire.duration then
		util.wait(self.stances.fire.duration)
	end

	if self.helper then self.helper:runScripts("gunfire-postauto", self) end

	self.cooldownTimer = self.fireTime --* self.energymax

	--FU/FR special checks
	self:hasShotgunReload()--reloads as a shotgun?
	self:checkAmmo() --is it an ammo user?

	self:setState(self.cooldown)
end

function GunFireFixed:burst() -- burst auto should be a thing here
	--ammo
	self.reloadTime = config.getParameter("reloadTime") or 1		-- how long does reloading mag take?
	self:checkMagazine()--ammo system magazine check
	-- recoil stats reset every time we shoot so that it is consistent
	self.recoilSpeed = (config.getParameter("recoilSpeed",200))
	self.recoilForce = (config.getParameter("recoilForce",100))

	if self.helper then
		self.helper:runScripts("gunfire-burst", self)
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

	if not self.burstCooldown then
		self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
	else
		self.cooldownTimer = self.burstCooldown
	end
	--FU/FR special checks
	self:hasShotgunReload()--reloads as a shotgun?
	self:checkAmmo() --is it an ammo user?

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

		progress = math.min(1.0, progress + ((self.dt or 0) / self.stances.cooldown.duration))
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
	params.power = self:damagePerShot() + (params.weaponBonus or 0)
	params.powerMultiplier = activeItem.ownerPowerMultiplier()
	params.speed = util.randomInRange(params.speed)
	self.timerReloadBar = 0 -- reset reload timer
	self:isResetting() --check if we reset the FU/FR crit bonus for crossbow and sniper

	if not projectileType then
		projectileType = self.projectileType
	end
	if type(projectileType)=="table" then
		projectileType = projectileType[math.random(#projectileType)]
	end

	local projectileId = 0
	for _ = 1, (projectileCount or self.projectileCount) do
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
	--Recoil here
	self:applyRecoil()
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
	local e=self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
	if (self.isAmmoBased==1) and not (self.fireMode=="alt") then --ammo based guns use 1/2 as much energy
		e=e/2
	elseif self.useEnergy=="nil" or self.useEnergy then -- key "useEnergy" defaults to true.
		--do nothing
	else
		e=0
	end
	return e
end

function GunFireFixed:damagePerShot()
	return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end

function GunFireFixed:uninit()
	--these actually have no fucking effect (outside the stat), because the variables wont persist for idk what reason.  likely due to scope. -khe
	status.clearPersistentEffects("weaponBonus")
	if (self.isAmmoBased==1) then
		if self.magazineAmount then
			--sb.logInfo("self.abilitySlot %s self.magazineAmount %s self.isReloading %s",self.abilitySlot,self.magazineAmount,self.isReloading)
			--activeItem.setInstanceValue("magazineAmount",self.magazineAmount)
			activeItem.setInstanceValue("magazineAmount"..self.abilitySlot,self.magazineAmount)
			activeItem.setInstanceValue("isReloading"..self.abilitySlot,self.isReloading)
		end
	end
end

function GunFireFixed:isResetting()
	-- FR/FU crossbow/sniper specials get reset here
	if (self.isSniper==1) or (self.isCrossbow==1) then
		self.firedWeapon = 1
		self.timeBeforeCritBoost = 2
		status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 0}})
	end
end

function GunFireFixed:isChargeUp()
	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
	if (self.isCrossbow >= 1) or (self.isSniper >= 1) then
		self.countdownDelay = (self.countdownDelay or 0) + 1
		self.weaponBonus = (self.weaponBonus or 0)
		self.firedWeapon = (self.firedWeapon or 0)
		--workaround for variable scope issue
		if status.statPositive("fu_cleanupWeaponBonus") then
			status.setPersistentEffects("weaponBonus", {})
			self.firedWeapon=1
		end
		if (self.firedWeapon >= 1) then
			if (self.isCrossbow==1) then
				if self.countdownDelay > 20 then
					self.weaponBonus = 0
					self.countdownDelay = 0
					self.firedWeapon = 0
				end
			elseif (self.isSniper==1) then
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

		if (self.isSniper==1) and (self.weaponBonus >= 80) then --limit max value for crits and let player know they maxed
			self.weaponBonus = 80
			status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
			status.addEphemeralEffect("critReady")
		elseif (self.isCrossbow==1) and (self.weaponBonus >= 50) then --limit max value for crits and let player know they maxed
			self.weaponBonus = 50
			status.setPersistentEffects("critCharged", {{stat = "isCharged", amount = 1}})
			status.addEphemeralEffect("critReady")
		else
			status.removeEphemeralEffect("critReady")
		end
		--this section's stat changes were moved to the update block to address unintended effects.
		--status.setPersistentEffects("weaponBonus", {{stat = "critChance", amount = self.weaponBonus}}) -- set final bonus value
	end
end

function GunFireFixed:hasShotgunReload()
	self.isReloader = config.getParameter("isReloader",0) -- is this a shotgun style reload?
	if self.isReloader >= 1 then
		animator.playSound("cooldown") -- adds sound to shotgun reload
		if (self.isAmmoBased==1) and (self.magazineAmount <= 0) then
			animator.playSound("fuReload") -- adds new sound to reload
		end
	end
end

function GunFireFixed:checkAmmo(force)
	-- set the cursor to the Reload cursor
	if (self.isAmmoBased==1) then -- ammo bar color check
		if self.currentAmmoPercent <= 0 then
			self.barColor = {0,0,0,255}
			activeItem.setCursor("/cursors/fureticle5.cursor")
		elseif self.currentAmmoPercent <= 0.25 then
			self.barColor = {201,49,49,125}
			activeItem.setCursor("/cursors/fureticle5.cursor")
		elseif self.currentAmmoPercent <= 0.45 then
			self.barColor = {201,133,49,125}
			activeItem.setCursor("/cursors/fureticle4.cursor")
		elseif self.currentAmmoPercent <= 0.55 then
			self.barColor = {201,179,49,125}
			activeItem.setCursor("/cursors/fureticle3.cursor")
		elseif self.currentAmmoPercent <= 0.65 then
			self.barColor = {167,201,49,125}
			activeItem.setCursor("/cursors/fureticle2.cursor")
		elseif self.currentAmmoPercent <= 0.75 then
			self.barColor = {130,201,49,125}
			activeItem.setCursor("/cursors/fureticle1.cursor")
		else
			self.barColor = {0,250,112,125}
			activeItem.setCursor("/cursors/fureticle1.cursor")
		end
	end
	if (self.isAmmoBased==1) and (force or (self.magazineAmount <= 0)) then
		self.isReloading=true
		activeItem.setInstanceValue("isReloading"..self.abilitySlot,self.isReloading)
		if self.burstCooldown then
			self.cooldownTimer = self.burstCooldown + self.reloadTime
		else
			self.cooldownTimer = self.fireTime + self.reloadTime
		end
		status.addEphemeralEffect("reloadReady", 0.5)
		self.magazineAmount = self.magazineSize
		self.reloadTime = config.getParameter("reloadTime",0)
		-- set the cursor to the Reload cursor
		if (self.reloadTime < 1) then
			if animator.hasSound("fuReload") then
				animator.playSound("fuReload") -- adds new sound to reload
			end
		elseif (self.reloadTime >= 2.5) then
			if animator.hasSound("fuReload5") then
				animator.playSound("fuReload5") -- adds new sound to reload
			end
		elseif (self.reloadTime >= 2) then
			if animator.hasSound("fuReload4") then
				animator.playSound("fuReload4") -- adds new sound to reload
			end
		elseif (self.reloadTime >= 1.5) then
			if animator.hasSound("fuReload3") then
				animator.playSound("fuReload3") -- adds new sound to reload
			end
		elseif (self.reloadTime >= 1) then
			if animator.hasSound("fuReload2") then
				animator.playSound("fuReload2") -- adds new sound to reload
			end
		end

		--check current ammo and create an ammo bar to inform the user
		self.currentAmmoPercent = 1.0
		self.barColor = {0,250,112,125}

		if (self.fireMode=="primary") then
			if self.magazineAmount and self.magazineSize and (self.magazineSize > 1) then
				world.sendEntityMessage(
					activeItem.ownerEntityId(),
					"setBar",
					"ammoBar",
					util.clamp(self.currentAmmoPercent,0.0,1.0),
					self.barColor
				)
			end
			if self.magazineAmount then
				--activeItem.setInstanceValue("magazineAmount",self.magazineAmount)
				activeItem.setInstanceValue("magazineAmount"..self.abilitySlot,self.magazineAmount)
			end
			activeItem.setInstanceValue("isReloading"..self.abilitySlot,self.isReloading)
		end
		self.weapon:setStance(self.stances.cooldown)
		self:setState(self.cooldown)
	end
end

function GunFireFixed:checkMagazine(evalOnly)
	self:calcAmmo()
	self.magazineAmount = (self.magazineAmount or 0)-- current number of bullets in the magazine
	--self.isAmmoBased = config.getParameter("isAmmoBased",0)--this doesn't fucking belong here, but blah.
	self.isAmmoBased = self.isAmmoBased or ((self.abilitySlot=="primary") and config.getParameter("isAmmoBased",0))
	if (self.isAmmoBased==1) then
		--check current ammo and create an ammo bar to inform the user
		self.currentAmmoPercent = self.magazineAmount / self.magazineSize

		if (self.fireMode=="primary") then
			if self.magazineAmount and self.magazineSize and (self.magazineSize > 1) then
				world.sendEntityMessage(
					activeItem.ownerEntityId(),
					"setBar",
					"ammoBar",
					util.clamp(self.currentAmmoPercent,0.0,1.0),
					self.barColor
				)
			end
		end

		if not evalOnly then
			if self.magazineAmount <= 0 then
				self.weapon:setStance(self.stances.cooldown)
				self:setState(self.cooldown)
				self.magazineAmount = 0
			else
				self.magazineAmount = self.magazineAmount - 1
			end
		end
	end
end

function GunFireFixed:applyRecoil()
	--Recoil here
	if (self.hasRecoil==1) then --does the weapon have recoil?
		if (self.fireMode=="primary") then --is it primary fire?
			self.recoilForce = self.recoilForce * self.fireTime
			self:adjustRecoil()
		else
			self.recoilForce = self.recoilForce * 0.15
			self:adjustRecoil()
		end
		local recoilDirection = mcontroller.facingDirection()==1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
		mcontroller.controlApproachVelocityAlongAngle(recoilDirection, self.recoilSpeed, self.recoilForce, true)
	end
end

function GunFireFixed:adjustRecoil() -- if we are not grounded, we halve the force of the recoil
	if not mcontroller.onGround() then
		self.recoilForce = self.recoilForce * 0.5
	end
	if mcontroller.crouching() then
		self.recoilForce = self.recoilForce * 0.25
	end
end
