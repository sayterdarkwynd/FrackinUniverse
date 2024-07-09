require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

FUElementalSpin = WeaponAbility:new()

function FUElementalSpin:init()
	self:reset()
	self.cooldownTimer = self.cooldownTime
	self.primaryAbility = getPrimaryAbility()
	self.damageConfigMerged=util.mergeTable(self.primaryAbility.damageConfig,self.damageConfig)
end

function FUElementalSpin:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.weapon.currentAbility == nil and self.cooldownTimer == 0 and fireMode == "alt" and not status.resourceLocked("energy") then
		self:setState(self.windup)
	end
end

function FUElementalSpin:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	animator.setAnimationState("spinSwoosh", "spin")
	animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", true)
	self.weapon.aimAngle = 0
	activeItem.setOutsideOfHand(true)

	if animator.hasSound(self.weapon.elementalType.."Spin") then
		animator.playSound(self.weapon.elementalType.."Spin",-1)
	end

	local duration = self.stances.windup.duration
	while self.fireMode == "alt" or duration > 0 do
		duration = math.max(0, duration - self.dt)
		self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.spinRate * self.dt)

		if status.overConsumeResource("energy", self.energyUsage * self.dt) then
			local damageArea = partDamageArea("spinSwoosh")
			self.weapon:setDamage(self.damageConfigMerged, damageArea)
		elseif duration == 0 then
			break
		end

		coroutine.yield()
	end

	animator.stopAllSounds(self.weapon.elementalType.."Spin")

	if status.overConsumeResource("energy", self.projectileEnergyCost) then
		self:setState(self.fire)
	end

	self.cooldownTimer = self.cooldownTime
end

function FUElementalSpin:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", false)
	animator.setAnimationState("spinSwoosh", "idle")
	if animator.hasSound("SpinFire") then
		animator.playSound("SpinFire")
	end

	local position = vec2.add(mcontroller.position(), activeItem.handPosition())
	local params = copy(self.projectileParameters)
	params.powerMultiplier = activeItem.ownerPowerMultiplier()
	params.power = params.power * config.getParameter("damageLevelMultiplier")
	world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {self.weapon.aimDirection, 0}, false, params)

	util.wait(self.stances.fire.duration)
end

function FUElementalSpin:reset()
	animator.setAnimationState("spinSwoosh", "idle")
	animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", false)
	activeItem.setOutsideOfHand(false)
	animator.stopAllSounds(self.weapon.elementalType.."Spin")
end

function FUElementalSpin:uninit()
	self:reset()
end
