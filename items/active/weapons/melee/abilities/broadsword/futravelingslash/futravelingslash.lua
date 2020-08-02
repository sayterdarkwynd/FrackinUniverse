require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

TravelingSlash = WeaponAbility:new()

function TravelingSlash:init()
	self.cooldownTimer = self.cooldownTime
end

function TravelingSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
		self:setState(self.windup)
	end
end

function TravelingSlash:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	util.wait(self.stances.windup.duration)

	self:setState(self.fire)
end

function TravelingSlash:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
	local params = {
		powerMultiplier = activeItem.ownerPowerMultiplier(),
		power = self:damageAmount()
	}
	world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)

	if self:slashSound() then
	animator.playSound(self:slashSound())
	end

	util.wait(self.stances.fire.duration)
	self.cooldownTimer = self.cooldownTime
end

function TravelingSlash:slashSound()
	return self.weapon.elementalType.."TravelSlash"
end

function TravelingSlash:aimVector()
	return {mcontroller.facingDirection(), 0}
end

function TravelingSlash:damageAmount()
	return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function TravelingSlash:uninit()
end
