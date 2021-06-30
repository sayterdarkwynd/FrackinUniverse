require "/scripts/vec2.lua"
require "/scripts/util.lua"

CrystalStorm = WeaponAbility:new()

function CrystalStorm:init()
	storage.projectiles2 = storage.projectiles2 or {} --stupid conflicts

	self.elementalType = self.elementalType or self.weapon.elementalType

	self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
	self.stances = config.getParameter("stances")

	activeItem.setCursor("/cursors/reticle0.cursor")
	self.weapon:setStance(self.stances.idle)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
	self.castposition = nil
end

function CrystalStorm:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self:updateProjectiles()

	world.debugPoint(self:focusPosition(), "blue")

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then

		self:setState(self.charge)
	end
end

function CrystalStorm:charge()
	if #storage.projectiles2 > 1 then
		self.killProjectiles() --only one force of destruction per staff!
	end
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

function CrystalStorm:charged()
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

function CrystalStorm:discharge()
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

	animator.playSound(self.elementalType.."discharge")
	animator.stopAllSounds(self.elementalType.."chargedloop")

	self:setState(self.cooldown)
end

function CrystalStorm:cooldown()
	self.weapon:setStance(self.stances.cooldown)
	self.weapon.aimAngle = 0

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function()

	end)
end

function CrystalStorm:targetValid(aimPos)
	local focusPos = self:focusPosition()
	return world.magnitude(focusPos, aimPos) <= (self.maxCastRange*(1+status.stat("focalRangeMult")))
	and not world.lineTileCollision(mcontroller.position(), focusPos)
	and not world.lineTileCollision(focusPos, aimPos)
end

function CrystalStorm:createProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local aimVec = vec2.withAngle(0)
	local xoffset = {
		0,
		0.5,
		1,
		0.5,
		0,
		-0.5,
		-1,
		-0.5,
	}
	--local basePos = vec2.sub(aimPosition,{0,5})
	local basePos = aimPosition
	self.castPosition = basePos

	local pCount = self.projectileCount or 1
	-- bonus projectiles
	local bonus=status.stat("focalProjectileCountBonus")
	local flooredBonus=math.floor(bonus)
	if bonus~=flooredBonus then bonus=flooredBonus+(((math.random()<(bonus-flooredBonus)) and 1) or 0) end
	local singleMultiplier=1+(((pCount==1) and 0.1*bonus) or 0)
	pCount=pCount+bonus
	local pParams = copy(self.projectileParameters)

	pParams.power = singleMultiplier * self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	for i = 1, pCount do
		local position = vec2.add(basePos,	{xoffset[((i-1)%8)+1], 1.25 * (i - 1)})
		local projectileId = world.spawnProjectile(
			self.projectileType,
			position,
			activeItem.ownerEntityId(),
			aimVec,
			false,
			pParams
		)

		if projectileId then
			table.insert(storage.projectiles2, projectileId)
			world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
		end
	end
end

function CrystalStorm:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
function CrystalStorm:updateProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local newProjectiles = {}
	for _, projectileId in pairs(storage.projectiles2) do
		if world.entityExists(projectileId) then
			--projectile movement
			local position = world.entityPosition(projectileId)
			if world.magnitude(world.entityPosition(projectileId), {self.castPosition[1],position[2]}) >= 1.25 then
				world.sendEntityMessage(projectileId, "reverse")
			end
			local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
			if projectileResponse:finished() then
				local newIds = projectileResponse:result()
				if type(newIds) ~= "table" then
					newIds = {newIds}
				end
				for _, newId in pairs(newIds) do
					table.insert(newProjectiles, newId)
				end
			end
		end
	end
	storage.projectiles2 = newProjectiles
end

function CrystalStorm:killProjectiles()
	for _, projectileId in pairs(storage.projectiles2) do
		if world.entityExists(projectileId) then
			world.sendEntityMessage(projectileId, "kill")
		end
	end
end

function CrystalStorm:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
end

function CrystalStorm:uninit(weaponUninit)
	self:reset()
	if weaponUninit then self:killProjectiles() end
end
