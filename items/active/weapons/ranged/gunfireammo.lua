require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
	self.weapon:setStance(self.stances.idle)

	self.cooldownTimer = self.fireTime

	self.fireHeld = false
	self.weapon.cocked = not( self.fireType == "bolt" )

	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end
	self.hasRecoil = (config.getParameter("hasRecoil",0))--when fired, does the weapon have recoil?
	self.recoilSpeed = (config.getParameter("recoilSpeed",200))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
	self.recoilForce = (config.getParameter("recoilForce",100)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire
end

function GunFire:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if animator.animationState("firing") ~= "fire" then
		animator.setLightActive("muzzleFlash", false)
	end

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
	and not self.weapon.currentAbility
	and self.cooldownTimer == 0
	and (not status.resourceLocked("energy") or self:useEnergy())
	and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if (self.weapon.ammoAmount > 0) and (self.weapon.cocked) then
			if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
				self:setState(self.auto)
			elseif not self.fireHeld then
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.semi)
				end
			elseif self.fireType == "bolt" then
				self.weapon.cocked = false
				self:setState(self.semi)
			elseif self.fireType == "burst" then
				self:setState(self.burst)
			end
		else
			if not self.fireHeld and self.weapon.cocked then
				if self.fireType == "bolt" and self.weapon.cocked then
					self.weapon.cocked = false
				end
				animator.playSound("empty")
				self:setState(self.cooldown)
			end
		end
	end
	self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function GunFire:auto()
		-- recoil
		self.recoilSpeed = (config.getParameter("recoilSpeed",200))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
		self.recoilForce = (config.getParameter("recoilForce",100)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire

	self.weapon:setStance(self.stances.fire)

		self:fireProjectile()
		self:muzzleFlash()
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")

	if self.stances.fire.duration then
		util.wait(self.stances.fire.duration)
	end

	self.cooldownTimer = self.fireTime
	self:setState(self.cooldown)
end

function GunFire:semi()
		-- recoil
		self.recoilSpeed = (config.getParameter("recoilSpeed",200))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
		self.recoilForce = (config.getParameter("recoilForce",100)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire

	self.weapon:setStance(self.stances.fire)

		self:fireProjectile()
		self:muzzleFlash()
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")

	if self.stances.fire.duration then
		util.wait(self.stances.fire.duration)
	end

	self.cooldownTimer = self.fireTime/10
	self:setState(self.cooldown)
end

function GunFire:burst()
		-- recoil
		self.recoilSpeed = (config.getParameter("recoilSpeed",200))-- speed of recoil. Ideal is around 200 on the item. Default is 1 here
		self.recoilForce = (config.getParameter("recoilForce",100)) --force of recoil. Ideal is around 1500 on the item but can be whatever you desire

	self.weapon:setStance(self.stances.fire)

	local shots = math.min(self.burstCount,self.weapon.ammoAmount)
	while shots > 0 and (status.overConsumeResource("energy", self:energyPerShot())or self:useEnergy()) do
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
		self:fireProjectile()
		self:muzzleFlash()
		shots = shots - 1

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

	animator.setAnimationState("gunState","firing")

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
	animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
	animator.setAnimationState("firing", "fire")
	animator.burstParticleEmitter("muzzleFlash")
	animator.playSound("fire")

	animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
	--Recoil here
	self:applyRecoil()
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
	for _ = 1, (projectileCount or self.projectileCount) do
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

function GunFire:useEnergy()
	return not self.energyUsage
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
	return (self.energyUsage or 0) * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
	return ((self.baseDamage or (self.baseDps * self.fireTime))+self.bonusDps) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()
end


function GunFire:applyRecoil()
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

function GunFire:adjustRecoil()		-- if we are not grounded, we halve the force of the recoil
		if not mcontroller.onGround() then
		 self.recoilForce = self.recoilForce * 0.5
		end
		if mcontroller.crouching() then
		 self.recoilForce = self.recoilForce * 0.25
		end
end
