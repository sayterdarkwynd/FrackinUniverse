require "/scripts/vec2.lua"

function init()
	self.recoil = 0
	self.recoilRate = 0

	self.fireOffset = config.getParameter("fireOffset")
	updateAim()
	self.active = false

	storage.fireTimer = storage.fireTimer or 0
end

function update(dt, fireMode, shiftHeld)
	updateAim()
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	if self.active then
		if world.getProperty("ephemeral") then
			self.active=false
			return
		end
			self.isUnique = config.getParameter("isUnique")
			raceroller()
			if shiftHeld and self.isUnique~=1 then
				self.crewrace = player.species()
			end
			item.consume(1)
			local crewtype = config.getParameter("crewtype.crewname")
			local seed = sb.makeRandomSource():randu64()
			local parameters = {}
			local crewrace = self.crewrace
			world.spawnNpc(mcontroller.position(), crewrace, crewtype, 1, seed, parameters)
	end
end

function activate(fireMode, shiftHeld)
	if storage.fireTimer > 0 then
		return
	end
	storage.fireTimer=3
	if world.entityType(activeItem.ownerEntityId()) ~= "player" then
		sb.logInfo("Crew Contract: Someone is a moron.")
		return
	end
	if world.getProperty("ephemeral") then
		world.sendEntityMessage(activeItem.ownerEntityId(), "queueRadioMessage", "fuCrewContractInvalidLocation", 1.0)
		return
	end
	if not storage.firing then
		self.active = true
	end
end

function updateAim()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
	self.aimAngle = self.aimAngle + self.recoil
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
	local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
	aimVector[1] = aimVector[1] * self.aimDirection
	return aimVector
end

function holdingItem()
	return true
end

function recoil()
	return false
end

function outsideOfHand()
	return false
end


function raceroller()
	self.isUnique = config.getParameter("isUnique")

	if self.isUnique then
		self.crewrace = config.getParameter("race")
	else
		local crewNpcList = root.assetJson("/items/active/crewcontracts/crewcontract.activeitem").crewNpcTypes or {}
		self.raceroller = math.random(#crewNpcList)
		self.crewrace = crewNpcList[self.raceroller] or "human"
	end
end
