require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
	storage.projectiles = storage.projectiles or {}

	self.elementalType = self.elementalType or self.weapon.elementalType

	self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
	self.stances = config.getParameter("stances")

	activeItem.setCursor("/cursors/reticle0.cursor")
	self.weapon:setStance(self.stances.idle)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end

end

function ControlProjectile:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self:updateProjectiles()

	world.debugPoint(self:focusPosition(), "blue")

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then
		self:setState(self.charge)
	end

end

function ControlProjectile:charge()
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

function ControlProjectile:charged()
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

	self:setState(self.discharge)
end

function ControlProjectile:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then
		animator.playSound(self.elementalType.."activate")
		self:createProjectiles()
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
		return
	end

	util.wait(self.stances.discharge.duration, function(dt)
		status.setResourcePercentage("energyRegenBlock", 1.0)
	end)

	while #storage.projectiles > 0 do
		if self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.lastFireMode ~= self.fireMode then
			self:killProjectiles()
		end
		self.lastFireMode = self.fireMode

		status.setResourcePercentage("energyRegenBlock", 1.0)
		coroutine.yield()
	end

	animator.playSound(self.elementalType.."discharge")
	animator.stopAllSounds(self.elementalType.."chargedloop")

	self:setState(self.cooldown)
end

function ControlProjectile:cooldown()
	self.weapon:setStance(self.stances.cooldown)
	self.weapon.aimAngle = 0

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function()

	end)
end

function ControlProjectile:targetValid(aimPos)
	local focusPos = self:focusPosition()
	return world.magnitude(focusPos, aimPos) <= (self.maxCastRange * (1+status.stat("focalRangeMult")))
	and not world.lineTileCollision(mcontroller.position(), focusPos)
	and not world.lineTileCollision(focusPos, aimPos)
end

function ControlProjectile:createProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
	local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
	local basePos = activeItem.ownerAimPosition()

	local pCount = self.projectileCount or 1
	-- bonus projectiles
	local bonus=status.stat("focalProjectileCountBonus")
	local flooredBonus=math.floor(bonus)
	if bonus~=flooredBonus then bonus=flooredBonus+(((math.random()<(bonus-flooredBonus)) and 1) or 0) end
	local singleMultiplier=1+(((pCount==1) and 0.1*bonus) or 0)
	pCount=((self.disableProjectileCountBonus and 0) or bonus)+pCount
	local pParams = copy(self.projectileParameters)

	pParams.power = singleMultiplier * self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	for _ = 1, pCount do
		local projectileId = world.spawnProjectile(
				self.projectileType,
				vec2.add(basePos, pOffset),
				activeItem.ownerEntityId(),
				pOffset,
				false,
				pParams
			)

		if projectileId then
			table.insert(storage.projectiles, projectileId)
			world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
		end

		pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
	end
end

function ControlProjectile:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
function ControlProjectile:updateProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local newProjectiles = {}
	local n=0
	for _, projectileId in pairs(storage.projectiles) do
		n=n+1
		if world.entityExists(projectileId) then
			local aP=aimPosition
			if n>1 then
				aP[1]=aP[1]+(2*n*(math.random(0.0,1.0)-0.5))
				aP[2]=aP[2]+(2*n*(math.random(0.0,1.0)-0.5))
			end
			local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", aP)
			if projectileResponse:finished() then
				local newIds = projectileResponse:result()
				if type(newIds) ~= "table" then
					newIds = {newIds}
				end
				for _, newId in pairs(newIds) do
					table.insert(newProjectiles, newId)
				end
			end
		else
			n=n-1
		end
	end
	storage.projectiles = newProjectiles
end

function ControlProjectile:killProjectiles()
	for _, projectileId in pairs(storage.projectiles) do
		if world.entityExists(projectileId) then
			world.sendEntityMessage(projectileId, "kill")
		end
	end
end

function ControlProjectile:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
end

function ControlProjectile:uninit(weaponUninit)
	self:reset()
	if weaponUninit then
		self:killProjectiles()
	end
end
