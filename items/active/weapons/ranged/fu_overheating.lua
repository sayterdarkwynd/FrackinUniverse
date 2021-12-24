require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/crits.lua"
require "/stats/effects/fu_statusUtil.lua"

-- Base gun fire ability
FUOverHeating = WeaponAbility:new()

function FUOverHeating:init()

	self.isReloader = config.getParameter("isReloader",0)
	-- **** FR ADDITIONS
	daytime = daytimeCheck()
	underground = undergroundCheck()
	lightLevel = 1

	-- bonus add for novakids with pistols when sped up, specifically to energy and damage equations at end of file so that they still damage and consume energy at high speed
	self.energyMax = 1
	-- ** END FR ADDITIONS

	self.weapon:setStance(self.stances.idle)
	self.cooldownTimer = self.fireTime

	-- ********************** BEGIN FU additions **************************
	self.isReloader = config.getParameter("isReloader",0)					 -- is this a shotgun style reload?
	self.isCrossbow = config.getParameter("isCrossbow",0)					 -- is this a crossbow?
	self.isSniper = config.getParameter("isSniper",0)						 -- is this a sniper rifle?
	self.isAmmoBased = config.getParameter("isAmmoBased",0)					 -- is this a ammo based gun?
	self.isMachinePistol = config.getParameter("isMachinePistol",0)				 -- is this a machine pistol?
	self.isShotgun = config.getParameter("isShotgun",0)						 -- is this a shotgun?

	calcAmmo(self)
	--self.magazineAmount = math.min(config.getParameter("magazineAmount",-1),self.magazineSize) -- current number of bullets in the magazine
	self.magazineAmount = config.getParameter("magazineAmount",-1) -- current number of bullets in the magazine
	-- params
	self.countdownDelay = 0									 -- how long till it regains damage bonus?
	self.timeBeforeCritBoost = 2									-- how long before it starts accruing bonus again?
	if (self.isAmmoBased == 1) then
		self.timerRemoveAmmoBar = 0
		self.currentAmmoPercent = util.clamp(self.magazineAmount / self.magazineSize,0.0,1.0)
		self.isReloading=(self.magazineAmount <= 0) or config.getParameter("isReloading"..self.abilitySlot,true)
	end

	-- set the overheating values
	self.currentHeat = config.getParameter("heat",0)
	self.overheatActive = config.getParameter("overheat", false)
	self.timerIdle = 0	--timer before returning to Idle state
	-- play cooling animation here
	animator.setParticleEmitterActive("heatVenting",self.overheatActive)

	-- ********************** END FU additions **************************

	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end
	self.hasRecoil = (config.getParameter("hasRecoil",0))--when fired, does the weapon have recoil?
	self.recoilSpeed = (config.getParameter("recoilSpeed",0))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
	self.recoilForce = (config.getParameter("recoilForce",0)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire

end

--for some reason, this is overridden by gunfire.lua on the disruptor. okay? looks to be 'shenanigans'
function calcAmmo(self)
	local oldSize=self.magazineSize
	self.magazineSize = (config.getParameter("magazineSize",1)*(1+status.stat("magazineMultiplier"))) + math.max(0,status.stat("magazineSize")) -- total count of the magazine
	if (oldSize and oldSize~= self.magazineSize) then return true,oldSize end
end

-- ***********************************************************************************************************
-- ***********************************************************************************************************

function FUOverHeating:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	-- *** FU Weapon Additions
	if self.timeBeforeCritBoost <= 0 then --check sniper/crossbow crit bonus
		self:isChargeUp()
	else
		self.timeBeforeCritBoost = self.timeBeforeCritBoost -dt
	end

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	setupHelper(self, {"gunfire-update", "gunfire-auto", "gunfire-postauto", "gunfire-burst", "gunfire-postburst"})
	if self.helper then
	self.helper:runScripts("gunfire-update", self, dt, fireMode, shiftHeld)
	end

	-- ************ FU overheating idle timer
	self.timerIdle = math.min(self.coolingTime, self.timerIdle + self.dt)

	if animator.animationState("firing") ~= "fire" then
		animator.setLightActive("muzzleFlash", false)
	end

	-- ************** FU OVERHEATING
	-- set the current animation state depending on heat value of weapon
	if self.currentHeat >= self.overheatLevel then
		self.overheatLimitedCharge = config.getParameter("overheatLimitedCharge")	-- if this is set, you can never reach max overheat
		if not self.overheatLimitedCharge then
			self.overheatActive = true
			playSoundCooldown()
		end
		activeItem.setInstanceValue("overheat", true)
	elseif self.currentHeat >= self.highLevel then
		animator.setAnimationState("weapon", "high")
		self.playCooldownSound = true
	elseif self.currentHeat >= self.medLevel then
		animator.setAnimationState("weapon", "med")
	elseif self.currentHeat >= self.lowLevel then
		animator.setAnimationState("weapon", "low")
	else
		animator.setAnimationState("weapon", "idle")
	end

	-- when not overheated, cool down passively
	if self.timerIdle == self.coolingTime and not self.overheatActive then
		self.currentHeat = math.max(0, self.currentHeat - (self.heatLossLevel * self.dt))
		activeItem.setInstanceValue("heat", self.currentHeat)
	end

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
	and not self.weapon.currentAbility
	and self.cooldownTimer == 0
	and not self.overheatActive
	and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		local changed,from=calcAmmo(self)
		if changed then
			if self.magazineSize>from then
				self.magazineAmount=math.min(self.magazineSize,self.magazineAmount+(self.magazineSize-from))
			elseif self.magazineSize < from then
				self.magazineAmount=math.min(self.magazineSize,self.magazineAmount)
			end
		end
		if self.fireType == "auto" then
			self:setState(self.auto)
		elseif self.fireType == "burst" then
			self:setState(self.burst)
		end
	elseif self.overheatActive then-- is currently overheated
		self:setState(self.overheating)
	end
end

function playSoundCooldown()
	if (self.playCooldownSound==true) then
		animator.playSound("cooldown")
		self.playCooldownSound = false
	end
end

function FUOverHeating:auto()
	self.firedWeapon = 1
	-- ***********************************************************************************************************
	-- FR SPECIALS	(Weapon speed and other such things)
	-- ***********************************************************************************************************
	-- recoil stats reset every time we shoot so that it is consistent
	self.recoilSpeed = (config.getParameter("recoilSpeed",0))
	self.recoilForce = (config.getParameter("recoilForce",0))
	local species = world.entitySpecies(activeItem.ownerEntityId())

	if self.helper then
		self.helper:runScripts("gunfire-auto", self)
	end

	self.weapon:setStance(self.stances.fire)

	self:fireProjectile()
	self:muzzleFlash()

	if self.recoilVelocity then
		if not (self.crouchReduction and mcontroller.crouching()) then
			local recoilVelocity = vec2.mul(vec2.norm(vec2.mul(self:aimVector(0), -1)), self.recoilVelocity)

			if (self.weapon.aimAngle <= 0 and not mcontroller.zeroG()) then
			mcontroller.setYVelocity(0)
			end
			mcontroller.addMomentum(recoilVelocity)
			mcontroller.controlJump()

		elseif self.crouchRecoilVelocity then
			local recoilVelocity = vec2.mul(vec2.norm(vec2.mul(self:aimVector(0), -1)), self.crouchRecoilVelocity)
			mcontroller.setYVelocity(0)
			mcontroller.addMomentum(recoilVelocity)
		end
	end


	if self.stances.fire.duration then
		util.wait(self.stances.fire.duration)
	end

	if self.helper then self.helper:runScripts("gunfire-postauto", self) end

	self.cooldownTimer = self.fireTime
	self:setState(self.cooldown)

	-- Is it a reloading weapon?
	self.isReloader = config.getParameter("isReloader",0)
	if (self.isReloader) >= 1 then
		animator.playSound("reload") -- adds new sound to reload
	end
end

function FUOverHeating:burst()
	self.firedWeapon = 1

	-- recoil stats reset every time we shoot so that it is consistent
	self.recoilSpeed = (config.getParameter("recoilSpeed",0))
	self.recoilForce = (config.getParameter("recoilForce",0))
	local species = world.entitySpecies(activeItem.ownerEntityId())

	if self.helper then
			self.helper:runScripts("gunfire-burst", self)
	end

	self.weapon:setStance(self.stances.fire)

	local shots = self.burstCount
	while shots > 0 do
		self:fireProjectile()
		self:muzzleFlash()
		shots = shots - 1

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

		util.wait(self.burstTime)
	end

	self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function FUOverHeating:cooldown()
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

function FUOverHeating:overheating()
	--set the stance
	self.weapon:setStance(self.stances.overheat)
	self.weapon:updateAim()
	-- reset aim
	self.weapon.aimAngle = 0
	while self.currentHeat > 0 do
		animator.setParticleEmitterActive("heatVenting",true)
		animator.setAnimationState("weapon","overheat")
		self.currentHeat = math.max(0, self.currentHeat - (self.heatLossRateMax * self.dt))
		activeItem.setInstanceValue("heat",self.currentHeat)
		coroutine.yield()
	end

	self.overheatActive = false
	activeItem.setInstanceValue("overheat",false)
	animator.setParticleEmitterActive("heatVenting",false)
end


function FUOverHeating:muzzleFlash()
	animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
	animator.setAnimationState("firing", "fire")
	animator.burstParticleEmitter("muzzleFlash")
	animator.playSound("fire")

	animator.setLightActive("muzzleFlash", true)
end

function FUOverHeating:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
	local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
	params.power = self:damagePerShot()
	params.powerMultiplier = activeItem.ownerPowerMultiplier()
	params.speed = util.randomInRange(params.speed)

	-- *********** FU heat
	self.currentHeat = self.currentHeat + self.heatGain
	activeItem.setInstanceValue("heat",self.currentHeat)
	self.timerIdle = 0

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
		--Recoil here
	self:applyRecoil()
	return projectileId
end

function FUOverHeating:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function FUOverHeating:aimVector(inaccuracy)
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function FUOverHeating:energyPerShot()
	return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function FUOverHeating:damagePerShot() --return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
	return Crits.setCritDamage(self, (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount)
end


function FUOverHeating:uninit()
	status.clearPersistentEffects("weaponBonus") --clear bonuses
	if (self.isAmmoBased == 1) then
		if self.magazineAmount then
			activeItem.setInstanceValue("magazineAmount",self.magazineAmount)
			activeItem.setInstanceValue("isReloading"..self.abilitySlot,self.isReloading)
		end
	end
end

function FUOverHeating:isResetting()
	-- FR/FU crossbow/sniper specials get reset here
	if (self.isSniper == 1) or (self.isCrossbow == 1) then
		self.firedWeapon = 1
		self.timeBeforeCritBoost = 2
		status.setPersistentEffects("critCharged", {
		--{stat = "isCharged", amount = 0}
	})
	end
end

function FUOverHeating:applyRecoil()
	--Recoil here
	if (self.hasRecoil == 1) then							--does the weapon have recoil?
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

function FUOverHeating:adjustRecoil()		-- if we are not grounded, we halve the force of the recoil
	if not mcontroller.onGround() then
		self.recoilForce = self.recoilForce * 0.5
	end
	if mcontroller.crouching() then
		self.recoilForce = self.recoilForce * 0.25
	end
end

function FUOverHeating:isChargeUp()
	self.isCrossbow = config.getParameter("isCrossbow",0) -- is this a crossbow?
	self.isSniper = config.getParameter("isSniper",0) -- is this a sniper rifle?
	if (self.isCrossbow >= 1) or (self.isSniper >= 1) then
		-- setting core params
		self.countdownDelay = (self.countdownDelay or 0) + 1 --increase chargeup Count each time this is called
		self.weaponBonus = (self.weaponBonus or 0) -- default is 0
		self.firedWeapon = (self.firedWeapon or 0) -- default is 0

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
	end
end