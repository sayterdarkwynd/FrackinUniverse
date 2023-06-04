require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

ElementalAura = WeaponAbility:new()

function ElementalAura:init()
	self:reset()
	self.cooldownTimer = self.cooldownTime
	self.activeTimer = 0
end

function ElementalAura:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.weapon.currentAbility == nil
		and self.cooldownTimer == 0
		and self.fireMode == "alt"
		and not status.resourceLocked("energy")
		and status.resource("energy") >= self.energyUsage * (self.minChargeTime / self.chargeTime) then

		self:setState(self.windup)
	end

	if self.active then
		self.activeTimer = math.max(0, self.activeTimer - self.dt)
		if self.activeTimer > 0 then
			self.weapon:setOwnerDamage(self.damageConfig, self.damagePoly)
		else
			self:deactivate()
		end
	end
end

-- Attack state: windup
function ElementalAura:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	animator.setParticleEmitterActive(self.weapon.elementalType.."Charge", true)
	animator.playSound(self.weapon.elementalType.."charge")

	local wasFull = false
	local chargeTimer = 0
	while self.fireMode == "alt" and (chargeTimer == self.chargeTime or status.overConsumeResource("energy", (self.energyUsage / self.chargeTime) * self.dt)) do
		chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)

		if chargeTimer == self.chargeTime and not wasFull then
			wasFull = true
			animator.stopAllSounds(self.weapon.elementalType.."charge")
			animator.playSound(self.weapon.elementalType.."full", -1)
		end

		local chargeRatio = math.sin(chargeTimer / self.chargeTime * 1.57)
		self.weapon.relativeArmRotation = util.toRadians(util.lerp(chargeRatio, {self.stances.windup.armRotation, self.stances.windup.endArmRotation}))
		self.weapon.relativeWeaponRotation = util.toRadians(util.lerp(chargeRatio, {self.stances.windup.weaponRotation, self.stances.windup.endWeaponRotation}))

		coroutine.yield()
	end

	animator.setParticleEmitterActive(self.weapon.elementalType.."Charge", false)
	animator.stopAllSounds(self.weapon.elementalType.."charge")
	animator.stopAllSounds(self.weapon.elementalType.."full")

	if chargeTimer > self.minChargeTime then
		self.activeTimer = self.duration * (chargeTimer / self.chargeTime)
		self:setState(self.fire)
	end
end

-- Attack state: fire
function ElementalAura:fire()
	self.weapon:setStance(self.stances.fire)

	self:activate()

	util.wait(self.stances.fire.duration)

	self.cooldownTimer = self.cooldownTime
end

function ElementalAura:activate()
	status.setPersistentEffects("entropicWarding", { "entropicward" })
	animator.playSound(self.weapon.elementalType.."activate")
	if not self.active then
		animator.playSound(self.weapon.elementalType.."active", -1)
	end
	self.active = true
end

function ElementalAura:deactivate()
	status.clearPersistentEffects("entropicWarding")
	animator.stopAllSounds(self.weapon.elementalType.."active")
	animator.playSound(self.weapon.elementalType.."deactivate")
	self.active = false
end

function ElementalAura:reset()
	animator.setParticleEmitterActive(self.weapon.elementalType.."Charge", false)
	animator.stopAllSounds(self.weapon.elementalType.."charge")
	animator.stopAllSounds(self.weapon.elementalType.."full")
end

function ElementalAura:uninit(final)
	if final then
		status.clearPersistentEffects("entropicWarding")
		animator.stopAllSounds(self.weapon.elementalType.."active")
	end
	self:reset()
end
