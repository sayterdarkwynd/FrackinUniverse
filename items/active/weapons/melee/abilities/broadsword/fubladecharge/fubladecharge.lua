require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

BladeCharge = WeaponAbility:new()

function BladeCharge:init()
	BladeCharge:reset()

	self.cooldownTimer = 0
end

function BladeCharge:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.cooldownTimer == 0 and not self.weapon.currentAbility and not status.resourceLocked("energy") and self.fireMode == "alt" then
		self:setState(self.windup)
	end
end

function BladeCharge:windup()
	self.weapon:setStance(self.stances.windup)

	animator.setAnimationState("bladeCharge", "charge")
	animator.setParticleEmitterActive("bladeCharge", true)

	local chargeTimer = self.chargeTime
	while self.fireMode == "alt" do
		chargeTimer = math.max(0, chargeTimer - self.dt)
		if chargeTimer == 0 then
			animator.setGlobalTag("bladeDirectives", "border=2;"..self.chargeBorder..";ee437799")
		end
		coroutine.yield()
	end

	if chargeTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
		self:setState(self.slash)
	end
end

function BladeCharge:slash()
	self.weapon:setStance(self.stances.slash)
	self.weapon:updateAim()

	animator.setAnimationState("bladeCharge", "idle")
	animator.setParticleEmitterActive("bladeCharge", false)
	animator.setAnimationState("swoosh", "fire")
	if animator.hasSound("chargedSwing") then
		animator.playSound("chargedSwing")
	end

	util.wait(self.stances.slash.duration, function()
		local damageArea = partDamageArea("swoosh")
		self.weapon:setDamage(self.damageConfig, damageArea)
	end)

	self.cooldownTimer = self.cooldownTime
end

function BladeCharge:reset()
	animator.setGlobalTag("bladeDirectives", "")
	animator.setParticleEmitterActive("bladeCharge", false)
	animator.setAnimationState("bladeCharge", "idle")
end

function BladeCharge:uninit()
	self:reset()
end
