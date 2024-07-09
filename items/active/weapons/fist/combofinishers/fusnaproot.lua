require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Snaproot = WeaponAbility:new()

function Snaproot:init()
	self.freezeTimer = 0

	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end
	self.primaryAbility = getPrimaryAbility()
	self.damageConfigMerged=util.mergeTable(self.primaryAbility.damageConfig,self.damageConfig)
end

-- Ticks on every update regardless if this is the active ability
function Snaproot:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
	if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
		mcontroller.controlApproachVelocity({0, 0}, 1000)
	end
end

-- used by fist weapon combo system
function Snaproot:startAttack()
	self:setState(self.windup)

	self.weapon.freezesLeft = 0
	self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function Snaproot:windup()
	self.weapon:setStance(self.stances.windup)

	util.wait(self.stances.windup.duration)

	self:setState(self.windup2)
end

-- State: windup2
function Snaproot:windup2()
	self.weapon:setStance(self.stances.windup2)

	util.wait(self.stances.windup2.duration)

	self:setState(self.fire)
end

-- State: special
function Snaproot:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	animator.setAnimationState("attack", "special")
	animator.playSound("special")

	status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)

	util.wait(self.stances.fire.duration, function()
		local damageArea = partDamageArea("weapon")

		self.weapon:setDamage(self.damageConfigMerged, damageArea, self.fireTime)
	end)

	finishFistCombo()
	activeItem.callOtherHandScript("finishFistCombo")
end

function Snaproot:uninit(unloaded)
	self.weapon:setDamage()
end
