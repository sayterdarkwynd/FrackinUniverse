require "/scripts/vec2.lua"
require "/scripts/FRHelper.lua"
require "/items/active/weapons/crits.lua"

-- Bow primary ability
BowShot = WeaponAbility:new()

function BowShot:init()
	self.energyPerShot = self.energyPerShot or 0

	self.drawTime = 0
	self.cooldownTimer = self.cooldownTime

	self:reset()

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function BowShot:update(dt, fireMode, shiftHeld)
	--*************************************
	-- FU/FR ADDONS
	setupHelper(self, "bowshot-fire")
	--*************************************

	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyPerShot == 0 or not status.resourceLocked("energy")) then
		self:setState(self.draw)
	end
end

function BowShot:uninit()
	--*************************************
	-- FU/FR ADDONS
	if self.helper then
		self.helper:clearPersistent()
	end
	--*************************************

	self:reset()
end

function BowShot:reset()
	animator.setGlobalTag("drawFrame", "0")
	self.weapon:setStance(self.stances.idle)
	status.setStatusProperty(activeItem.hand().."Firing",nil)
end

function BowShot:draw()
	self.weapon:setStance(self.stances.draw)

	animator.playSound("draw")
	status.setStatusProperty(activeItem.hand().."Firing",true)
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

	--*************************************
	-- FU/FR ADDONS
	if self and self.helper then
		self.helper:runScripts("bowshot-fire", self)
	end
	--*************************************

	if not world.pointTileCollision(self:firePosition()) and status.overConsumeResource("energy", self.energyPerShot) then
		world.spawnProjectile(
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

		util.wait(self.stances.fire.duration)
	end

	self.cooldownTimer = self.cooldownTime
	status.setStatusProperty(activeItem.hand().."Firing",false)
end

function BowShot:perfectTiming()
	return self.drawTime > self.powerProjectileTime[1] and self.drawTime < self.powerProjectileTime[2]
end

function BowShot:currentProjectileParameters()
	local projectileParameters = copy(self.projectileParameters or {})
	local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.projectileType)
	projectileParameters.speed = (projectileParameters.speed or projectileConfig.speed) * root.evalFunction(self.drawSpeedMultiplier, self.drawTime) * (1+status.stat("arrowSpeedMultiplier"))
	projectileParameters.power = projectileParameters.power or projectileConfig.power
	--projectileParameters.power = projectileParameters.power* self.weapon.damageLevelMultiplier* root.evalFunction(self.drawPowerMultiplier, self.drawTime) + BowShot:setCritDamage(damage)
	projectileParameters.power = Crits.setCritDamage(self, projectileParameters.power* self.weapon.damageLevelMultiplier* root.evalFunction(self.drawPowerMultiplier, self.drawTime))
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
