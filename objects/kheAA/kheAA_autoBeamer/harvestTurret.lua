require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/epoch.lua"


function init()
	-- Positions and angles
	self.baseOffset = config.getParameter("baseOffset")
	self.basePosition = vec2.add(object.position(), self.baseOffset)
	self.tipOffset = config.getParameter("tipOffset") --This is offset from BASE position, not object origin
	self.offAngle = util.toRadians(config.getParameter("offAngle", -30))

	-- Targeting
	self.targetQueryRange = config.getParameter("targetQueryRange",4)
	checkIsTheDate(true)
	-- Initialize turret
	object.setInteractive(false)

	self.state = FSM:new()
	self.state:set(offState)
end

function update(dt)
	if not deltaCheckDate or deltaCheckDate > 60 then
		deltaCheckDate=0
		checkIsTheDate()
	else
		deltaCheckDate=deltaCheckDate+dt
	end
	self.state:update(dt)
	world.debugPoint(firePosition(), "green")
end

----------------------------------------------------------------------------------------------------------
-- States

function offState()
	animator.setAnimationState("attack", "dead")
	animator.playSound("powerDown")
	object.setAllOutputNodes(false)

	while true do
		animator.rotateGroup("gun", self.offAngle)
		if active() then break end
		coroutine.yield()
	end

	animator.playSound("powerUp")
	self.state:set(scanState)
end


function scanState()
	animator.setAnimationState("attack", "idle")
	util.wait(0.5)
	animator.playSound("scan")
	object.setAllOutputNodes(false)

	local scan = coroutine.wrap(
		function()
			while true do
				animator.rotateGroup("gun", self.offAngle)
				local target = findTarget()
				if target then
					return self.state:set(fireState, target)
				end
				util.wait(1.0)
			end
		end
	)

	while true do

	scan()

	if not active() then break end
	coroutine.yield()
	end

	self.state:set(offState)
end

function fireState(targetId)
	animator.setAnimationState("attack", "attack")
	animator.playSound("foundTarget")
	object.setAllOutputNodes(true)

	local maxFireAngle = util.toRadians(config.getParameter("maxFireAngle"))
	local fire = coroutine.wrap(autoFire)

	while true do
		if not active() then return self.state:set(offState) end
		if not validTarget(targetId) then break end

		local targetPosition = world.entityPosition(targetId)
		local toTarget = world.distance(targetPosition, self.basePosition)
		local targetDistance = world.magnitude(toTarget)
		local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])

		if targetDistance > (self.targetQueryRange+4) or targetDistance < 2.5 or world.lineTileCollision(self.basePosition, targetPosition) then break end
		if math.abs(targetAngle) > util.toRadians(360) then break end

		animator.rotateGroup("gun", targetAngle)

		local rotation = animator.currentRotationAngle("gun")
		if math.abs(util.angleDiff(targetAngle, rotation)) < maxFireAngle then
			fire(targetId)
		end

		coroutine.yield()
	end

	util.wait(1.0)
	self.state:set(scanState)
end

----------------------------------------------------------------------------------------------------------
-- Helping functions, not states

function active()
	if object.isInputNodeConnected(0) then
		return object.getInputNodeLevel(0)
	end

	storage.active = storage.active ~= nil and storage.active or true
	return storage.active
end

function firePosition()
	local animationPosition = vec2.div(config.getParameter("animationPosition"), 8)
	local fireOffset = vec2.add(animationPosition, animator.partPoint("gun", "projectileSource"))
	return vec2.add(object.position(), fireOffset)
end

-- Coroutine
function autoFire(target)
	local types=targetTypes(target)
	local rotation = animator.currentRotationAngle("gun")
	local aimVector = {object.direction() * math.cos(rotation), math.sin(rotation)}

	while true do
		if types.eType=="player" then
			world.sendEntityMessage(target,"applyStatusEffect","nude")
		elseif types.farmbeast then
			world.callScriptedEntity(target,"dropMonsterHarvest")
		elseif types.bug then
			world.spawnProjectile("bugzap", firePosition(), entity.id(), aimVector)
		elseif types.farmable or types.eType=="plant" then
			local buffer={}
			local entPos=world.entityPosition(target)

			for _,coord in pairs(world.objectSpaces(target)) do
				local coordBuffer=vec2.add(coord,entPos)
				coordBuffer={world.xwrap(coordBuffer[1]),coordBuffer[2]}
				table.insert(buffer,coordBuffer)
			end

			world.damageTiles(buffer, "foreground", world.entityPosition(target), "plantish", 0.2, 1)
		end
		animator.playSound("fire")
		util.wait(config.getParameter("fireTime",0.1))
	end
end

-- Coroutine
function findTarget()
	local nearEntities = world.entityQuery(self.basePosition, self.targetQueryRange,{includedTypes=self.targetEntityTypes})
	return util.find(nearEntities,
		function(entityId)
			return validTarget(entityId)
		end
	)
end


function validTarget(entityId)
	if not entityId then
		return false
	end
	if not world.entityExists(entityId) then
		return false
	end

	local targetPosition = world.entityPosition(entityId)
	if world.lineTileCollision(self.basePosition, targetPosition) then
		return false
	end

	local toTarget = world.distance(targetPosition, self.basePosition)
	if not ( world.magnitude(toTarget) > 2.5 and math.abs(math.atan(toTarget[2], object.direction() * toTarget[1])) < util.toRadians(360) ) then
		return false
	end

	local types=targetTypes(entityId)
	if not types.void then
		for name,value in pairs(types) do
			if name~="eType" then
				if value then
					if self.validTargetTypes[name] then
						return true
					end
				end
			elseif value=="player" or value=="npc" or value=="plant" then
				return true
			end
		end
	end
	return false
end


function targetTypes(entityId)
	local types={}
	if not entityId or not world.entityExists(entityId) then
		types.void=true
		return types
	end
	types.eType=world.entityType(entityId)

	if types.eType=="monster" then
		types.farmbeast=not not world.callScriptedEntity(entityId,"isMonsterHarvestable")
		types.bug=not not contains(world.callScriptedEntity(entityId,"config.getParameter","scripts") or {},"/monsters/bugs/bug.lua")
	elseif types.eType=="object" then
		local tStage=world.farmableStage(entityId)
		if tStage ~= nil then
			stages=world.getObjectParameter(entityId,"stages")
			if stages ~= nil then
				if stages[tStage+1].harvestPool ~= nil then
					types.farmable=true
				end
			end
		else
			types.farmable=false
		end
	end

	return types
end

function checkIsTheDate(atInit)
	local epoDat=epoch.currentToTable()
	if epoDat.day==1 and epoDat.month==4 then
		if atInit or not isTheDate then
			isTheDate=true
			setTET()
		end
	else
		if atInit or isTheDate then
			isTheDate=false
			setTET()
		end
	end
end

function setTET()
	self.targetEntityTypes=config.getParameter("targetEntityTypes",{})
	self.validTargetTypes=config.getParameter("validTargetTypes",{})

	if isTheDate then
		for _,a in pairs({"player","npc"}) do
			if not contains(self.targetEntityTypes,a) then
				table.insert(self.targetEntityTypes,a)
			end
		end
	end
end