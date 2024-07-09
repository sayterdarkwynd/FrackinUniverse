require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

FlipSlash = WeaponAbility:new()

function FlipSlash:init()
	self.cooldownTimer = self.cooldownTime
	self.primaryAbility = getPrimaryAbility()
	self.damageConfigMerged=util.mergeTable(self.primaryAbility.damageConfig,self.damageConfig)
end

function FlipSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if not self.weapon.currentAbility
		and self.cooldownTimer == 0
		and self.fireMode == "alt"
		and not status.statPositive("activeMovementAbilities")
		and status.overConsumeResource("energy", self.energyUsage) then
		if mcontroller.onGround() then self:setState(self.windupground)
		else self:setState(self.windupair) end
	end
end

function FlipSlash:windupground()
	self.weapon:setStance(self.stances.windup)

	status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

	util.wait(self.stances.windup.duration, function(dt) mcontroller.controlCrouch() end)

	self:setState(self.flip)
end

--nerfed july 21 2019 : increased delay
function FlipSlash:windupair()
	self.weapon:setStance(self.stances.windup)

	status.setPersistentEffects("weaponMovementAbility", {
		{stat = "activeMovementAbilities", amount = 1}
	})

	util.wait(self.stances.windup.duration*1.5, function(dt)	--was / 4
			mcontroller.controlCrouch()
		end)

	self:setState(self.flip)
end

function FlipSlash:flip()
	self.weapon:setStance(self.stances.flip)
	self.weapon:updateAim()

	animator.setAnimationState("swoosh", "flip")
	if animator.hasSound(self.fireSound or "flipSlash") then
		animator.playSound(self.fireSound or "flipSlash")
	end
	animator.setParticleEmitterActive("flip", true)

	self.flipTime = self.rotations * self.rotationTime
	self.flipTimer = 0

	self.jumpTimer = self.jumpDuration

	while self.flipTimer < self.flipTime do
		self.flipTimer = self.flipTimer + self.dt

		mcontroller.controlParameters(self.flipMovementParameters)
		--mcontroller.controlModifiers({speedModifier=100.0})
		mcontroller.controlModifiers({runningSuppressed=true})

		if self.jumpTimer > 0 then
			self.jumpTimer = self.jumpTimer - self.dt
			--mcontroller.setYVelocity(self.jumpVelocity[2])
			mcontroller.setVelocity(self:aimVelocity(self.jumpVelocity[2]))
		end

		local damageArea = partDamageArea("swoosh")
		self.weapon:setDamage(self.damageConfigMerged, damageArea, self.fireTime)

		mcontroller.setRotation(-math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

		coroutine.yield()
	end

	status.clearPersistentEffects("weaponMovementAbility")

	animator.setAnimationState("swoosh", "idle")
	mcontroller.setRotation(0)
	animator.setParticleEmitterActive("flip", false)
	self.cooldownTimer = self.cooldownTime
end

function FlipSlash:aimVelocity(speed)
	return vec2.mul(vec2.norm(world.distance(activeItem.ownerAimPosition(),entity.position())),speed)
end

function FlipSlash:uninit()
	status.clearPersistentEffects("weaponMovementAbility")
	animator.setAnimationState("swoosh", "idle")
	mcontroller.setRotation(0)
	animator.setParticleEmitterActive("flip", false)
end
