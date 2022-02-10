require "/scripts/util.lua"
require "/scripts/rect.lua"
require "/scripts/pathutil.lua"
require "/items/active/weapons/weapon.lua"

BlinkSlash = WeaponAbility:new()

function BlinkSlash:init()
	self:reset()

	self.cooldownTimer = 0
end

function BlinkSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.weapon.currentAbility == nil
		 and self.fireMode == "alt"
		 --and mcontroller.onGround()
		 and self.cooldownTimer == 0
		 and not status.statPositive("activeMovementAbilities")
		 and not status.resourceLocked("energy") then

		self:setState(self.windup)
	end
end

function BlinkSlash:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	status.setPersistentEffects("weaponMovementAbility", {
		{stat = "activeMovementAbilities", amount = 1}
	})

	util.wait(self.stances.windup.duration)

	self.blinkPosition = self:findBlinkPosition()
	if self.blinkPosition and status.overConsumeResource("energy", self.energyUsage) then
		self:setState(self.slash)
	else
		self.cooldownTimer = self.cooldownTime
	end
end

function BlinkSlash:slash()
	local suppressMove = function()
		mcontroller.controlModifiers({movementSuppressed = true})
		mcontroller.controlParameters({
			gravityEnabled = false
		})
		mcontroller.setVelocity({0,0})
	end

	local slash = coroutine.create(self.slashAction)
	coroutine.resume(slash, self)

	while util.parallel(suppressMove, slash) do
		coroutine.yield()
	end
end

function BlinkSlash:slashAction()
	status.addEphemeralEffect("defense5")
	status.addEphemeralEffect("blink")
	util.wait(0.25)

	mcontroller.setPosition(self.blinkPosition)
	self.weapon.aimDirection = -self.weapon.aimDirection
	self.weapon:setStance(self.stances.slash)
	self.weapon:updateAim()

	util.wait(0.1)

	animator.setAnimationState("blinkSwoosh", "fire")
	if animator.hasSound("fire") then
		animator.playSound("fire")
	end

	util.wait(self.stances.slash.duration, function()
		local damageArea = partDamageArea("blinkSwoosh")
		self.weapon:setDamage(self.damageConfig, damageArea)
		mcontroller.setVelocity({75 * self.weapon.aimDirection, 0})
	end)

	self.weapon.aimDirection = -self.weapon.aimDirection

	self.cooldownTimer = self.cooldownTime
end

function BlinkSlash:reset()
	status.clearPersistentEffects("weaponMovementAbility")
	status.removeEphemeralEffect("defense5")
	animator.setGlobalTag("directives", "")
end

function BlinkSlash:uninit()
	self:reset()
end

function BlinkSlash:findBlinkPosition()
	local blinkDistance = self.blinkDistance
	while blinkDistance > 0 do
		local searchPosition = vec2.add(mcontroller.position(), {blinkDistance * mcontroller.facingDirection(), 0})
		local groundPosition = findGroundPosition(searchPosition, -self.blinkYTolerance, self.blinkYTolerance, false, {"Null", "Block", "Dynamic", "Platform"})
		if groundPosition and (not self.requireLineOfSight or not world.lineTileCollision(mcontroller.position(), groundPosition, {"Null", "Block", "Dynamic"})) then
			return groundPosition
		else
			blinkDistance = blinkDistance - 1
		end
	end

	return findGroundPosition(mcontroller.position(), -self.blinkYTolerance, self.blinkYTolerance, false, {"Null", "Block", "Dynamic", "Platform"})
end
