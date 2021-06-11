require "/scripts/vec2.lua"
require "/scripts/util.lua"

Controlledteleport = WeaponAbility:new()

function Controlledteleport:init()
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

--On each step;
function Controlledteleport:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	--self:updateProjectiles()

	world.debugPoint(self:focusPosition(), "blue")

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then
	local aimPosition = activeItem.ownerAimPosition()

		self:setState(self.charge)
	end
end



function Controlledteleport:charge()
	self.weapon:setStance(self.stances.charge)

	animator.playSound(self.elementalType.."charge")
	animator.setAnimationState("charge", "charge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)
	activeItem.setCursor("/cursors/charge2.cursor")

	local chargeTimer = ((status.statPositive("admin") or player.isAdmin()) and 0) or (self.stances.charge.duration * (1+status.stat("focalCastTimeMult")) * 0.45)
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

-- On fully charged
function Controlledteleport:charged()
	self.weapon:setStance(self.stances.charged)

	animator.playSound(self.elementalType.."fullcharge")
	animator.playSound(self.elementalType.."chargedloop", -1)
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)

	local targetValid
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		targetValid = self:targetValid(mcontroller.collisionPoly(),activeItem.ownerAimPosition())
		activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	self:setState(self.discharge)
end

function Controlledteleport:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")
	local wType=world.type()
	local permittedWorld =
	(status.statPositive("admin") or player.isAdmin())
	or ((world.terrestrial() or wType == "asteroids" or wType == "outpost" or wType == "unknown" or wType == "playerstation") and world.dayLength() ~= 100000)
	or (wType=="scienceoutpost" and player.hasCountOfItem("sciencebrochure2")>0)
	local lineOfSightActive = not world.lineTileCollision(activeItem.ownerAimPosition(), mcontroller.position())

	if (permittedWorld) then --and lineOfSightActive) then --make sure they can see destination so they cant cheat
		local finalLocation=self:targetValid(mcontroller.collisionPoly(),activeItem.ownerAimPosition());
		if finalLocation and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then
			animator.playSound(self.elementalType.."activate")
			self:blink(finalLocation)
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
				--self:killProjectiles()
			end
			self.lastFireMode = self.fireMode

			status.setResourcePercentage("energyRegenBlock", 1.0)
			coroutine.yield()
		end

		animator.playSound(self.elementalType.."discharge")
		animator.stopAllSounds(self.elementalType.."chargedloop")

		self:setState(self.cooldown)
	else
		animator.playSound(self.elementalType.."discharge")
		animator.stopAllSounds(self.elementalType.."chargedloop")
	end
end

function Controlledteleport:cooldown()
	self.weapon:setStance(self.stances.cooldown)
	self.weapon.aimAngle = 0

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function()

	end)
end

function Controlledteleport:targetValid(collidePoly,aimPos)
	local resolvedPoint = world.resolvePolyCollision(collidePoly, aimPos, config.getParameter("teleportTolerance"))

	if not resolvedPoint then
		return false
	end
	local focusPos = self:focusPosition()
	if world.magnitude(focusPos, aimPos) <= (self.maxCastRange*(1+status.stat("focalRangeMult"))) then
		return resolvedPoint
	end
end


function Controlledteleport:blink(altTarget)
	local aimPosition = altTarget
	--aimPosition=self:teleportPosition(mcontroller.collisionPoly(),activeItem.ownerAimPosition());
	if aimPosition then
		mcontroller.setPosition(aimPosition)
	end
end

function Controlledteleport:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
--[[
function Controlledteleport:createProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
		mcontroller.setPosition(aimPosition);
end

function Controlledteleport:updateProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local newProjectiles = {}
	for _, projectileId in pairs(storage.projectiles) do
		if world.entityExists(projectileId) then
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
	storage.projectiles = newProjectiles
end

function Controlledteleport:killProjectiles()
	for _, projectileId in pairs(storage.projectiles) do
		if world.entityExists(projectileId) then
			world.sendEntityMessage(projectileId, "kill")
		end
	end
end
]]--

function Controlledteleport:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
end

function Controlledteleport:uninit(weaponUninit)
	self:reset()
	if weaponUninit then
		--self:killProjectiles()
	end
end


function Controlledteleport:blinkAdjust(position, doPathCheck, doCollisionCheck, doLiquidCheck, doStandCheck)
	local blinkCollisionCheckDiameter = config.getParameter("blinkCollisionCheckDiameter")
	local blinkVerticalGroundCheck = config.getParameter("blinkVerticalGroundCheck")
	local blinkFootOffset = config.getParameter("blinkFootOffset")

	if doPathCheck then
		local collisionBlocks = world.collisionBlocksAlongLine(mcontroller.position(), position, true, 1)
		if #collisionBlocks ~= 0 then
			local diff = world.distance(position, mcontroller.position())
			diff[1] = diff[1] / math.abs(diff[1])
			diff[2] = diff[2] / math.abs(diff[2])

			position = {collisionBlocks[1][1] - diff[1], collisionBlocks[1][2] - diff[2]}
		end
	end

	if doCollisionCheck and not checkCollision(position) then
		local spaceFound = false
		for i = 1, blinkCollisionCheckDiameter * 2 do
			if checkCollision({position[1] + i / 2, position[2] + i / 2}) then
				position = {position[1] + i / 2, position[2] + i / 2}
				spaceFound = true
				break
			end

			if checkCollision({position[1] - i / 2, position[2] + i / 2}) then
				position = {position[1] - i / 2, position[2] + i / 2}
				spaceFound = true
				break
			end

			if checkCollision({position[1] + i / 2, position[2] - i / 2}) then
				position = {position[1] + i / 2, position[2] - i / 2}
				spaceFound = true
				break
			end

			if checkCollision({position[1] - i / 2, position[2] - i / 2}) then
				position = {position[1] - i / 2, position[2] - i / 2}
				spaceFound = true
				break
			end
		end

		if not spaceFound then
			return nil
		end
	end

	if doStandCheck then
		local groundFound = false
		for i = 1, blinkVerticalGroundCheck * 2 do
			local checkPosition = {position[1], position[2] - i / 2}

			if world.pointCollision(checkPosition, false) then
				groundFound = true
				position = {checkPosition[1], checkPosition[2] + 0.5 - blinkFootOffset}
				break
			end
		end

		if not groundFound then
			return nil
		end
	end

	if doLiquidCheck and (world.liquidAt(position) or world.liquidAt({position[1], position[2] + blinkFootOffset})) then
		return nil
	end

	if doCollisionCheck and not checkCollision(position) then
		return nil
	end

	return position
end

function checkCollision(position)
	local collisionBounds = mcontroller.collisionBounds()
	collisionBounds[1] = collisionBounds[1] - mcontroller.position()[1] + position[1]
	collisionBounds[2] = collisionBounds[2] - mcontroller.position()[2] + position[2]
	collisionBounds[3] = collisionBounds[3] - mcontroller.position()[1] + position[1]
	collisionBounds[4] = collisionBounds[4] - mcontroller.position()[2] + position[2]

	return not world.rectCollision(collisionBounds)
end
