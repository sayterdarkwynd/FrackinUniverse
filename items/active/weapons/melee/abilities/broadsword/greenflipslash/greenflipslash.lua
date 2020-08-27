require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

GreenFlipSlash = WeaponAbility:new()

function GreenFlipSlash:init()
	self.cooldownTimer = self.cooldownTime
end

function GreenFlipSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if not self.weapon.currentAbility
		 and self.cooldownTimer == 0
		 and self.fireMode == "alt"
		 and mcontroller.onGround()
		 and not status.statPositive("activeMovementAbilities")
		 and status.overConsumeResource("energy", self.energyUsage) then

		self:setState(self.windup)
	end
end

function GreenFlipSlash:windup()
	self.weapon:setStance(self.stances.windup)

	status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

	util.wait(self.stances.windup.duration, function(dt)
			mcontroller.controlCrouch()
		end)

	self:setState(self.flip)
end

function GreenFlipSlash:flip()
	self.weapon:setStance(self.stances.flip)
	self.weapon:updateAim()

	animator.setAnimationState("swoosh", "flip")
	if animator.hasSound(self.fireSound or "greenflipSlash") then
	animator.playSound(self.fireSound or "greenflipSlash")
	end
	animator.setParticleEmitterActive("flip", true)

	self.flipTime = self.rotations * self.rotationTime
	self.flipTimer = 0

	self.jumpTimer = self.jumpDuration

	while self.flipTimer < self.flipTime do
		self.flipTimer = self.flipTimer + self.dt

		mcontroller.controlParameters(self.flipMovementParameters)

		if self.jumpTimer > 0 then
			self.jumpTimer = self.jumpTimer - self.dt
			mcontroller.setVelocity({self.jumpVelocity[1] * self.weapon.aimDirection, self.jumpVelocity[2]})
		end

		local damageArea = partDamageArea("swoosh")
		self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

		mcontroller.setRotation(-math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

		coroutine.yield()
	end

	status.clearPersistentEffects("weaponMovementAbility")

	animator.setAnimationState("swoosh", "idle")
	mcontroller.setRotation(0)
	animator.setParticleEmitterActive("flip", false)
	self.cooldownTimer = self.cooldownTime
end


function GreenFlipSlash:uninit()
	status.clearPersistentEffects("weaponMovementAbility")
	animator.setAnimationState("swoosh", "idle")
	mcontroller.setRotation(0)
	animator.setParticleEmitterActive("flip", false)
end
