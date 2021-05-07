require "/scripts/vec2.lua"
require "/scripts/util.lua"

EffectZone = WeaponAbility:new()

function EffectZone:init()
	self.elementalType = self.elementalType or self.weapon.elementalType

	activeItem.setCursor("/cursors/reticle0.cursor")

	self.weapon.onLeaveAbility = function() self:reset() end
end

function EffectZone:update(dt, fireMode, shiftHeld)
	local aimAngle,aimDirection = activeItem.aimAngleAndDirection(0,activeItem.ownerAimPosition())

	activeItem.setArmAngle(aimAngle)
	activeItem.setFacingDirection(aimDirection)

	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	if storage.projectileId and not world.entityExists(storage.projectileId) then
		storage.projectileId = nil
	end

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then
		self.leveledMaxCastRange=self.maxCastRange+config.getParameter("level",0)

		self:setState(self.charged)
	end
end

function EffectZone:charged()
	local targetValid
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		targetValid = self:targetValid(activeItem.ownerAimPosition())
		activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")
		coroutine.yield()
	end

	self:setState(self.discharge)
end

function EffectZone:discharge()
	activeItem.setCursor("/cursors/reticle0.cursor")
	if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost or self.energyUsage or 0) then
		animator.playSound("fire")
		self:createProjectile()
	else
		self:setState(self.cooldown)
		return
	end

	util.wait(0.1, function(dt) end)
	self:setState(self.cooldown)
end

function EffectZone:cooldown()
	activeItem.setCursor("/cursors/reticle0.cursor")
	local abilityCooldown=config.getParameter("abilityCooldown") or 0
	util.wait(abilityCooldown, function() end)
end

function EffectZone:targetValid(aimPos)
	local focusPos = self:focusPosition()
	return world.magnitude(focusPos, aimPos) <= (self.leveledMaxCastRange or 0) and not world.lineTileCollision(mcontroller.position(), focusPos) and not world.lineTileCollision(focusPos, aimPos)
end

function EffectZone:createProjectile()
	if storage.projectileId then
		world.sendEntityMessage(storage.projectileId, "kill")
	end

	local pParams = copy(self.projectileParameters)
	pParams.power = (pParams.baseDamage or 0) * (config.getParameter("damageLevelMultiplier") or 0)
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	storage.projectileId = world.spawnProjectile(self.projectileType,activeItem.ownerAimPosition(),activeItem.ownerEntityId(),{0, 0},false,pParams)
end

function EffectZone:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition())
end

function EffectZone:reset()
	activeItem.setCursor("/cursors/reticle0.cursor")
end

function EffectZone:uninit(weaponUninit)
	self:reset()
end
