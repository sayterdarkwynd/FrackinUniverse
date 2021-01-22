require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

RocketSpear = WeaponAbility:new()

function RocketSpear:init()
	self:reset()

	self.cooldownTimer = self.cooldownTime
end

function RocketSpear:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.weapon.currentAbility == nil
			and self.fireMode == "alt"
			and self.cooldownTimer == 0
			and (not self.boostSpeed or not status.statPositive("activeMovementAbilities"))
			and not status.resourceLocked("energy") then

		self:setState(self.windup)
	end
end

function RocketSpear:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	if self.boostSpeed then
		status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
	end

	animator.setAnimationState("chargeSwoosh", "charge")

	util.wait(self.stances.windup.duration)

	self:setState(self.fire)
end

function RocketSpear:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	animator.setAnimationState("chargeSwoosh", "full")
		if animator.hasSound(self.weapon.elementalType.."Start") then
		animator.playSound(self.weapon.elementalType.."Start")
	end
	if animator.hasSound(self.weapon.elementalType.."Blast") then
		animator.playSound(self.weapon.elementalType.."Blast")
	end

	local params = copy(self.projectileParameters)
	params.power = self.baseDps * self.fireTime * config.getParameter("damageLevelMultiplier")
	params.powerMultiplier = activeItem.ownerPowerMultiplier()

	local fireTimer = 0
	while self.fireMode == "alt" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
		self.weapon:updateAim()

		if self.boostSpeed then
			local boostAngle = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
			mcontroller.controlApproachVelocityAlongAngle(boostAngle, self.boostSpeed, self.boostForce, true)
		end

		fireTimer = math.max(0, fireTimer - self.dt)
		if fireTimer == 0 then
			fireTimer = self.fireTime
			local position = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("chargeSwoosh", "projectileSource")))
			local aim = self.weapon.aimAngle + util.randomInRange({-self.inaccuracy, self.inaccuracy})
			if not world.lineTileCollision(mcontroller.position(), position) then
				world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, params)
			end
		end

		coroutine.yield()
	end

	animator.stopAllSounds(self.weapon.elementalType.."Start")
	animator.stopAllSounds(self.weapon.elementalType.."Blast")
	animator.playSound(self.weapon.elementalType.."End")
	self.cooldownTimer = self.cooldownTime
end

function RocketSpear:reset()
	if self.boostSpeed then
		status.clearPersistentEffects("movementAbility")
	end
	animator.setAnimationState("chargeSwoosh", "idle")
	animator.stopAllSounds(self.weapon.elementalType.."Blast")
end

function RocketSpear:uninit()
	self:reset()
end
