require "/scripts/vec2.lua"
require "/scripts/util.lua"

EffectZone = WeaponAbility:new()

function EffectZone:init()
	self.elementalType = self.elementalType or self.weapon.elementalType

	activeItem.setCursor("/cursors/reticle0.cursor")

	self.stances = config.getParameter("stances")
	self.weapon:setStance(self.stances.idle)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function EffectZone:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	if storage.projectileId and not world.entityExists(storage.projectileId) then
		storage.projectileId = nil
	end

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then

		self:setState(self.charge)
	end
end

function EffectZone:charge()
	self.weapon:setStance(self.stances.charge)

	animator.playSound(self.elementalType.."charge")
	animator.setAnimationState("charge", "charge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)
	activeItem.setCursor("/cursors/charge2.cursor")

	local chargeTimer = self.stances.charge.duration * (1+status.stat("focalCastTimeMult"))
	while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		chargeTimer = chargeTimer - self.dt

		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	animator.stopAllSounds(self.elementalType.."charge")

	if chargeTimer <= 0 then
		self:setState(self.charged)
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
	end
end

function EffectZone:charged()
	self.weapon:setStance(self.stances.charged)

	animator.playSound(self.elementalType.."fullcharge")
	animator.playSound(self.elementalType.."chargedloop", -1)
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)

	local targetValid
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		targetValid = self:targetValid(activeItem.ownerAimPosition())
		activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	animator.stopAllSounds(self.elementalType.."chargedloop")

	self:setState(self.discharge)
end

function EffectZone:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost) then
		animator.playSound("zoneactivate")
		self:createProjectile()
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
		return
	end

	util.wait(self.stances.discharge.duration, function(dt)

	end)

	self:setState(self.cooldown)
end

function EffectZone:cooldown()
	self.weapon:setStance(self.stances.cooldown)

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function()

	end)
end

function EffectZone:targetValid(aimPos)
	local focusPos = self:focusPosition()
	return world.magnitude(focusPos, aimPos) <= (self.maxCastRange*(1+status.stat("focalRangeMult")))
	and not world.lineTileCollision(mcontroller.position(), focusPos)
	and not world.lineTileCollision(focusPos, aimPos)
end

function EffectZone:createProjectile()
	if storage.projectileId then
		world.sendEntityMessage(storage.projectileId, "kill")
	end

	local pParams = copy(self.projectileParameters)
	pParams.power = (pParams.baseDamage or 0) * config.getParameter("damageLevelMultiplier")
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	storage.projectileId = world.spawnProjectile(
		self.projectileType,
		activeItem.ownerAimPosition(),
		activeItem.ownerEntityId(),
		{0, 0},
		false,
		pParams
	)
end

function EffectZone:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

function EffectZone:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
end

function EffectZone:uninit(weaponUninit)
	self:reset()
end
