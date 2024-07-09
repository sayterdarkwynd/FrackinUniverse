require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

FUSpin = WeaponAbility:new()

function FUSpin:init()
	self.cooldownTimer = self.cooldownTime
	self:reset()
	self.primaryAbility = getPrimaryAbility()
	self.damageConfigMerged=util.mergeTable(self.primaryAbility.damageConfig,self.damageConfig)
end

function FUSpin:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.weapon.currentAbility == nil
		and self.cooldownTimer == 0
		and not status.resourceLocked("energy")
		and self.fireMode == "alt" then

		self:setState(self.spin)
	end
end

function FUSpin:spin()
	self.weapon:setStance(self.stances.spin)
	self.weapon:updateAim()

	animator.setAnimationState("spinSwoosh", "spin")
	self.weapon.aimAngle = 0
	activeItem.setOutsideOfHand(true)

	while self.fireMode == "alt" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
		self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.spinRate * self.dt)
		local damageArea = partDamageArea("spinSwoosh")
		self.weapon:setDamage(self.damageConfigMerged, damageArea)
		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end
	self.cooldownTimer = self.cooldownTime
end

function FUSpin:reset()
	animator.setAnimationState("spinSwoosh", "idle")
	activeItem.setOutsideOfHand(false)
end

function FUSpin:uninit()
	self:reset()
end
